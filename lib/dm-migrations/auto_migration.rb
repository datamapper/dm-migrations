require 'dm-core/adapters'

module DataMapper
  module Migrations
    module SingletonMethods

      # destructively migrates the repository upwards to match model definitions
      #
      # @param [Symbol] name repository to act on, :default is the default
      #
      # @api public
      def migrate!(repository_name = nil)
        repository(repository_name).migrate!
      end

      # drops and recreates the repository upwards to match model definitions
      #
      # @param [Symbol] name repository to act on, :default is the default
      #
      # @api public
      def auto_migrate!(repository_name = nil)
        repository_execute(:auto_migrate!, repository_name)
      end

      # @api public
      def auto_upgrade!(repository_name = nil)
        repository_execute(:auto_upgrade!, repository_name)
      end

      private

      # @api private
      def auto_migrate_down!(repository_name)
        repository_execute(:auto_migrate_down!, repository_name)
      end

      # @api private
      def auto_migrate_up!(repository_name)
        repository_execute(:auto_migrate_up!, repository_name)
      end

      # @api private
      def repository_execute(method, repository_name)
        DataMapper::Model.descendants.each do |model|
          model.send(method, repository_name || model.default_repository_name)
        end
      end
    end

    module Repository
      # Determine whether a particular named storage exists in this repository
      #
      # @param [String]
      #   storage_name name of the storage to test for
      #
      # @return [Boolean]
      #   true if the data-store +storage_name+ exists
      #
      # @api semipublic
      def storage_exists?(storage_name)
        adapter = self.adapter
        if adapter.respond_to?(:storage_exists?)
          adapter.storage_exists?(storage_name)
        end
      end

      # @api semipublic
      def upgrade_model_storage(model)
        adapter = self.adapter
        if adapter.respond_to?(:upgrade_model_storage)
          adapter.upgrade_model_storage(model)
        end
      end

      # @api semipublic
      def create_model_storage(model)
        adapter = self.adapter
        if adapter.respond_to?(:create_model_storage)
          adapter.create_model_storage(model)
        end
      end

      # @api semipublic
      def destroy_model_storage(model)
        adapter = self.adapter
        if adapter.respond_to?(:destroy_model_storage)
          adapter.destroy_model_storage(model)
        end
      end

      # Destructively automigrates the data-store to match the model.
      # First migrates all models down and then up.
      # REPEAT: THIS IS DESTRUCTIVE
      #
      # @api public
      def auto_migrate!
        DataMapper.auto_migrate!(name)
      end

      # Safely migrates the data-store to match the model
      # preserving data already in the data-store
      #
      # @api public
      def auto_upgrade!
        DataMapper.auto_upgrade!(name)
      end
    end # module Repository

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
  end

  module Adapters

    extend Chainable

    extendable do

      # @api private
      def const_added(const_name)
        require auto_migration_extensions(const_name)
        if DataMapper::Migrations.const_defined?(const_name)
          adapter = const_get(const_name)
          adapter.send(:include, DataMapper::Migrations.const_get(const_name))
        end
      rescue LoadError
        # do nothing
      ensure
        super
      end

      # @api private
      def auto_migration_extensions(const_name)
        name = const_name.to_s.gsub('Adapter','').downcase
        adapter_name = name == 'dataobjects' ? 'do' : name
        "dm-migrations/adapters/dm-#{adapter_name}-adapter"
      end

    end
  end

end
