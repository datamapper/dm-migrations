require 'dm-core'
require 'dm-migrations/migration'
require 'dm-migrations/auto_migration'

module DataMapper
  module Migrations
    def self.include_migration_api
      DataMapper.extend(SingletonMethods)
      [ :Repository, :Model ].each do |name|
        DataMapper.const_get(name).send(:include, const_get(name))
      end
      DataMapper::Model.append_extensions(Model)
      Adapters::AbstractAdapter.descendants.each do |adapter_class|
        Adapters.include_migration_api(DataMapper::Inflector.demodulize(adapter_class.name))
      end
    end
  end # module Migrations

  module Adapters
    def self.include_migration_api(const_name)
      require migration_extensions(const_name)

      if Migrations.const_defined?(const_name)
        adapter = const_get(const_name)
        adapter.send(:include, migration_module(const_name))
      end
    rescue LoadError
      # Silently ignore the fact that no adapter extensions could be required
      # This means that the adapter in use doesn't support migrations
    end

    def self.migration_module(const_name)
      Migrations.const_get(const_name)
    end

    private

    # @api private
    def self.migration_extensions(const_name)
      name = adapter_name(const_name)
      name = 'do' if name == 'dataobjects'

      return "dm-migrations/adapters/dm-#{name}-adapter"
    end

    extendable do
      # @api private
      def const_added(const_name)
        include_migration_api(const_name)
        super
      end
    end
  end # module Adapters

  Migrations.include_migration_api
end # module DataMapper
