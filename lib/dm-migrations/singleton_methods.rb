require 'dm-core'

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

      # @api semipublic
      def auto_migrate_down!(repository_name)
        repository_execute(:auto_migrate_down!, repository_name)
      end

      # @api semipublic
      def auto_migrate_up!(repository_name)
        repository_execute(:auto_migrate_up!, repository_name)
      end

      # @api private
      def repository_execute(method, repository_name)
        DataMapper::Model.descendants.each do |model|
          model.send(method, repository_name || model.default_repository_name)
        end
      end
    end # module SingletonMethods
  end # module Migrations
end # module DataMapper
