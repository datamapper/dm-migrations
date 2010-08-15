require 'dm-migrations/runner/class_methods'

require 'set'

module DataMapper
  module Migrations
    module Runner
      #
      # Registers a new migration namespace.
      #
      # @param [Module] base
      #   The namespace that will contain migrations.
      #
      # @since 1.0.1
      #
      def self.included(base)
        if base == Kernel
          base.send :include, ClassMethods
        else
          base.send :extend, ClassMethods
        end

        Runner.migration_namespaces << base
      end

      #
      # The registered migration namespaces.
      #
      # @return [Set<Module>]
      #   The registered modules that contain migrations.
      #
      # @since 1.0.1
      #
      def Runner.migration_namespaces
        @dm_migration_namespaces ||= Set[]
      end

      #
      # Migrates all migration namespaces upwards.
      #
      # @return [true]
      #   All migration namespaces were successfully migrated up.
      #
      # @since 1.0.1
      #
      def Runner.migrate_up!
        Runner.migration_namespaces.each do |migration_namespace|
          migration_namespace.migrate_up!
        end

        true
      end

      #
      # Migrates all migration namespaces downwards.
      #
      # @return [true]
      #   All migration namespaces were successfully migrated down.
      #
      # @since 1.0.1
      #
      def Runner.migrate_down!
        Runner.migration_namespaces.reverse_each do |migration_namespace|
          migration_namespace.migrate_down!
        end

        true
      end
    end
  end
end
