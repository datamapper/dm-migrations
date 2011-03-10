require 'dm-core'

module DataMapper
  module Migrations
    module Model

      # @api private
      def self.included(mod)
        mod.descendants.each { |model| model.extend self }
      end

      # @api semipublic
      def storage_exists?(repository_name = default_repository_name)
        repository(repository_name).storage_exists?(storage_name(repository_name))
      end

      # Destructively automigrates the data-store to match the model
      # REPEAT: THIS IS DESTRUCTIVE
      #
      # @param Symbol repository_name the repository to be migrated
      #
      # @api public
      def auto_migrate!(repository_name = self.repository_name)
        assert_valid(true)
        auto_migrate_down!(repository_name)
        auto_migrate_up!(repository_name)
      end

      # Safely migrates the data-store to match the model
      # preserving data already in the data-store
      #
      # @param Symbol repository_name the repository to be migrated
      #
      # @api public
      def auto_upgrade!(repository_name = self.repository_name)
        assert_valid(true)
        base_model = self.base_model
        if base_model == self
          repository(repository_name).upgrade_model_storage(self)
        else
          base_model.auto_upgrade!(repository_name)
        end
      end

      # Destructively migrates the data-store down, which basically
      # deletes all the models.
      # REPEAT: THIS IS DESTRUCTIVE
      #
      # @param Symbol repository_name the repository to be migrated
      #
      # @api private
      def auto_migrate_down!(repository_name = self.repository_name)
        assert_valid(true)
        base_model = self.base_model
        if base_model == self
          repository(repository_name).destroy_model_storage(self)
        else
          base_model.auto_migrate_down!(repository_name)
        end
      end

      # Auto migrates the data-store to match the model
      #
      # @param Symbol repository_name the repository to be migrated
      #
      # @api private
      def auto_migrate_up!(repository_name = self.repository_name)
        assert_valid(true)
        base_model = self.base_model
        if base_model == self
          repository(repository_name).create_model_storage(self)
        else
          base_model.auto_migrate_up!(repository_name)
        end
      end

    end # module Model
  end # module Migrations
end # module DataMapper
