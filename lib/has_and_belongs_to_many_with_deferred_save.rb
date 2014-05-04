module ActiveRecord
  module Associations
    module ClassMethods

      # Instructions:
      #
      # Replace your existing call to has_and_belongs_to_many with has_and_belongs_to_many_with_deferred_save.
      #
      # Then add a validation method that adds an error if there is something wrong with the (unsaved) collection. This will prevent it from being saved if there are any errors.
      #
      # Example:
      #
      #  def validate
      #    if people.size > maximum_occupancy
      #      errors.add :people, "There are too many people in this room"
      #    end
      #  end
      def has_and_belongs_to_many_with_deferred_save(*args)
        has_and_belongs_to_many *args
        collection_name = args[0].to_s
        collection_singular_ids = collection_name.singularize + "_ids"

        add_deletion_callback

        attr_accessor :"unsaved_#{collection_name}"
        attr_accessor :"use_original_collection_reader_behavior_for_#{collection_name}"

        define_method "#{collection_name}_with_deferred_save=" do |collection|
          #puts "has_and_belongs_to_many_with_deferred_save: #{collection_name} = #{collection.collect(&:id).join(',')}"
          self.send "unsaved_#{collection_name}=", collection
        end

        define_method "#{collection_name}_with_deferred_save" do |*args|
          if self.send("use_original_collection_reader_behavior_for_#{collection_name}")
            self.send("#{collection_name}_without_deferred_save")
          else
            if self.send("unsaved_#{collection_name}").nil?
              send("initialize_unsaved_#{collection_name}", *args)
            end
            self.send("unsaved_#{collection_name}")
          end
        end

        alias_method_chain :"#{collection_name}=", 'deferred_save'
        alias_method_chain :"#{collection_name}", 'deferred_save'

        define_method "#{collection_singular_ids}_with_deferred_save" do |*args|
          if self.send("use_original_collection_reader_behavior_for_#{collection_name}")
            self.send("#{collection_singular_ids}_without_deferred_save")
          else
            if self.send("unsaved_#{collection_name}").nil?
              send("initialize_unsaved_#{collection_name}", *args)
            end
            self.send("unsaved_#{collection_name}").map { |e| e[:id] }
          end
        end

        alias_method_chain :"#{collection_singular_ids}", 'deferred_save'

        # only needed for ActiveRecord >= 3.0
        if ActiveRecord::VERSION::STRING >= "3"
          define_method "#{collection_singular_ids}_with_deferred_save=" do |ids|
            ids = Array.wrap(ids).reject { |id| id.blank? }
            reflection_wrapper = self.send("#{collection_name}_without_deferred_save")
            new_values = reflection_wrapper.klass.find(ids)
            self.send("#{collection_name}=", new_values)
          end
          alias_method_chain :"#{collection_singular_ids}=", 'deferred_save'
        end

        define_method "do_#{collection_name}_save!" do
          # Question: Why do we need this @use_original_collection_reader_behavior stuff?
          # Answer: Because AssociationCollection#replace(other_array) performs a diff between current_array and other_array and deletes/adds only
          # records that have changed.
          # In order to perform that diff, it needs to figure out what "current_array" is, so it calls our collection_with_deferred_save, not
          # knowing that we've changed its behavior. It expects that method to return the elements of that collection that are in the *database*
          # (the original behavior), so we have to provide that behavior...  If we didn't provide it, it would end up trying to take the diff of
          # two identical collections so nothing would ever get saved.
          # But we only want the old behavior in this case -- most of the time we want the *new* behavior -- so we use
          # @use_original_collection_reader_behavior as a switch.

          self.send "use_original_collection_reader_behavior_for_#{collection_name}=", true
          if self.send("unsaved_#{collection_name}").nil?
            send("initialize_unsaved_#{collection_name}")
          end
          self.send "#{collection_name}_without_deferred_save=", self.send("unsaved_#{collection_name}")
            # /\ This is where the actual save occurs.
          self.send "use_original_collection_reader_behavior_for_#{collection_name}=", false

          true
        end
        after_save "do_#{collection_name}_save!"


        define_method "reload_with_deferred_save_for_#{collection_name}" do |*args|
          # Reload from the *database*, discarding any unsaved changes.
          self.send("reload_without_deferred_save_for_#{collection_name}", *args).tap do
            self.send "unsaved_#{collection_name}=", nil
              # /\ If we didn't do this, then when we called reload, it would still have the same (possibly invalid) value of
              # unsaved_collection that it had before the reload.
          end
        end
        alias_method_chain :reload, "deferred_save_for_#{collection_name}"


        define_method "initialize_unsaved_#{collection_name}" do |*args|
          #puts "Initialized to #{self.send("#{collection_name}_without_deferred_save").clone.inspect}"
          elements = self.send("#{collection_name}_without_deferred_save", *args).clone
          elements = ArrayToAssociationWrapper.new(elements)
          elements.defer_association_methods_to self, collection_name
          self.send "unsaved_#{collection_name}=", elements
            # /\ We initialize it to collection_without_deferred_save in case they just loaded the object from the
            # database, in which case we want unsaved_collection to start out with the "saved collection".
            # Actually, this doesn't clone the Association but the elements array instead (since the clone method is
            # proxied like any other methods)
            # Important: If we don't use clone, then it does an assignment by reference and any changes to unsaved_collection
            # will also change *collection_without_deferred_save*! (Not what we want! Would result in us saving things
            # immediately, which is exactly what we're trying to avoid.)



        end
        private :"initialize_unsaved_#{collection_name}"

      end

      def add_deletion_callback
        # this will delete all the association into the join table after obj.destroy,
        # but is only useful/necessary, if the record is not paranoid?
        unless (self.respond_to?(:paranoid?) && self.paranoid?)
          after_destroy { |record|
            begin
              record.save
            rescue Exception => e
              logger.warn "Association cleanup after destroy failed with #{e}"
            end
          }
        end
      end
    end
  end
end
