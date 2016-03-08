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
        collection_name = args[0].to_s
        collection_singular_ids = collection_name.singularize + '_ids'

        return if method_defined?("#{collection_name}_with_deferred_save")

        has_and_belongs_to_many *args

        add_deletion_callback

        attr_accessor :"unsaved_#{collection_name}"
        attr_accessor :"use_original_collection_reader_behavior_for_#{collection_name}"

        define_method "#{collection_name}_with_deferred_save=" do |collection|
          # puts "has_and_belongs_to_many_with_deferred_save: #{collection_name} = #{collection.collect(&:id).join(',')}"
          send "unsaved_#{collection_name}=", collection
        end

        define_method "#{collection_name}_with_deferred_save" do |*method_args|
          if send("use_original_collection_reader_behavior_for_#{collection_name}")
            send("#{collection_name}_without_deferred_save")
          else
            send("initialize_unsaved_#{collection_name}", *method_args) if send("unsaved_#{collection_name}").nil?
            send("unsaved_#{collection_name}")
          end
        end

        alias_method_chain :"#{collection_name}=", 'deferred_save'
        alias_method_chain :"#{collection_name}", 'deferred_save'

        define_method "#{collection_singular_ids}_with_deferred_save" do |*method_args|
          if send("use_original_collection_reader_behavior_for_#{collection_name}")
            send("#{collection_singular_ids}_without_deferred_save")
          else
            send("initialize_unsaved_#{collection_name}", *method_args) if send("unsaved_#{collection_name}").nil?
            send("unsaved_#{collection_name}").map { |e| e[:id] }
          end
        end

        alias_method_chain :"#{collection_singular_ids}", 'deferred_save'

        # only needed for ActiveRecord >= 3.0
        if ActiveRecord::VERSION::STRING >= '3'
          define_method "#{collection_singular_ids}_with_deferred_save=" do |ids|
            ids = Array.wrap(ids).reject(&:blank?)
            reflection_wrapper = send("#{collection_name}_without_deferred_save")
            new_values = reflection_wrapper.klass.find(ids)
            send("#{collection_name}=", new_values)
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

          send "use_original_collection_reader_behavior_for_#{collection_name}=", true
          send("initialize_unsaved_#{collection_name}") if send("unsaved_#{collection_name}").nil?
          send "#{collection_name}_without_deferred_save=", send("unsaved_#{collection_name}")
          # /\ This is where the actual save occurs.
          send "use_original_collection_reader_behavior_for_#{collection_name}=", false

          true
        end
        after_save "do_#{collection_name}_save!"

        define_method "reload_with_deferred_save_for_#{collection_name}" do |*method_args|
          # Reload from the *database*, discarding any unsaved changes.
          send("reload_without_deferred_save_for_#{collection_name}", *method_args).tap do
            send "unsaved_#{collection_name}=", nil
            # /\ If we didn't do this, then when we called reload, it would still have the same (possibly invalid) value of
            # unsaved_collection that it had before the reload.
          end
        end
        alias_method_chain :reload, "deferred_save_for_#{collection_name}"

        define_method "initialize_unsaved_#{collection_name}" do |*method_args|
          # puts "Initialized to #{self.send("#{collection_name}_without_deferred_save").clone.inspect}"
          elements = send("#{collection_name}_without_deferred_save", *method_args)
          elements = ArrayToAssociationWrapper.new(elements)
          elements.defer_association_methods_to self, collection_name
          send "unsaved_#{collection_name}=", elements
        end
        private :"initialize_unsaved_#{collection_name}"
      end

      def add_deletion_callback
        # this will delete all the association into the join table after obj.destroy,
        # but is only useful/necessary, if the record is not paranoid?
        unless respond_to?(:paranoid?) && paranoid?
          after_destroy do |record|
            begin
              record.save
            rescue Exception => e
              logger.warn "Association cleanup after destroy failed with #{e}"
            end
          end
        end
      end
    end
  end
end
