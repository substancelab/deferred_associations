module ActiveRecord
  module Associations
    module ClassMethods

      def has_many_with_deferred_save *args
        has_many *args

        collection_name         = args[0].to_s

        if args[1].is_a?(Hash) && args[1].keys.include?(:through)
          logger.warn "You are using the option :through on #{self.name}##{collection_name}. This was not tested very much with has_many_with_deferred_save. Please write many tests for your functionality!"
        end

        after_save "hmwds_update_#{collection_name}"

        define_obj_setter    collection_name
        define_obj_getter    collection_name
        define_id_setter     collection_name

        define_update_method collection_name
        define_reload_method collection_name
      end


      def define_obj_setter collection_name

        define_method("#{collection_name}_with_deferred_save=") do |objs|
          instance_variable_set "@hmwds_temp_#{collection_name}", objs || []
        end

        method_name = "#{collection_name}="
        alias_method_chain method_name, :deferred_save
      end

      def define_obj_getter collection_name

        define_method("#{collection_name}_with_deferred_save") do
          save_in_progress = instance_variable_get "@hmwds_#{collection_name}_save_in_progress"

          # while updating the association, rails loads the association object - this needs to be the original one
          unless save_in_progress
            elements  = instance_variable_get "@hmwds_temp_#{collection_name}"
            if elements.nil?
              elements = ArrayToAssociationWrapper.new(self.send("#{collection_name}_without_deferred_save"))
              elements.defer_association_methods_to self, collection_name
              instance_variable_set "@hmwds_temp_#{collection_name}", elements
            end

            result = elements
          else
            result = self.send("#{collection_name}_without_deferred_save")
          end

          result
        end

        alias_method_chain collection_name, :deferred_save
      end

      def define_id_setter collection_name
        # only needed for ActiveRecord >= 3.0
        if ActiveRecord::VERSION::STRING >= "3"
          collection_singular_ids = "#{collection_name.singularize}_ids"
          define_method "#{collection_singular_ids}_with_deferred_save=" do |ids|
            ids = Array.wrap(ids).reject { |id| id.blank? }
            new_values = self.send("#{collection_name}_without_deferred_save").klass.find(ids)
            self.send("#{collection_name}=", new_values)
          end
          alias_method_chain :"#{collection_singular_ids}=", 'deferred_save'
        end
      end

      def define_update_method collection_name

        define_method "hmwds_update_#{collection_name}" do

          unless frozen?
            elements = instance_variable_get "@hmwds_temp_#{collection_name}"
            unless elements.nil? # nothing has been done with the association
              # save is done automatically, if original behaviour is restored
              instance_variable_set "@hmwds_#{collection_name}_save_in_progress", true
              self.send("#{collection_name}_without_deferred_save=", elements)
              instance_variable_set "@hmwds_#{collection_name}_save_in_progress", false

              instance_variable_set "@hmwds_temp_#{collection_name}", nil
            end
          end
        end
      end

      def define_reload_method collection_name
        define_method "reload_with_deferred_save_for_#{collection_name}" do
          # Reload from the *database*, discarding any unsaved changes.
          self.send("reload_without_deferred_save_for_#{collection_name}").tap do
            instance_variable_set "@hmwds_temp_#{collection_name}", nil
          end
        end
        alias_method_chain :"reload", "deferred_save_for_#{collection_name}"
      end
    end
  end
end