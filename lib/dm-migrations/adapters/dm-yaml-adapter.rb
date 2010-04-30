require 'dm-migrations/auto_migration'
require 'dm-migrations/adapters/dm-do-adapter'

module DataMapper
  module Migrations
    module YamlAdapter

      def self.included(base)
        DataMapper.extend(Migrations::SingletonMethods)
        [ :Repository, :Model ].each do |name|
          DataMapper.const_get(name).send(:include, Migrations.const_get(name))
        end
      end

      # @api semipublic
      def destroy_model_storage(model)
        yaml_file(model).unlink if yaml_file(model).file?
        true
      end

    end
  end
end
