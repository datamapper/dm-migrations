require 'dm-migrations/migration'
require 'dm-core'

require 'rubygems/version'

module DataMapper
  module Migrations
    module Runner
      module ClassMethods
        include DataMapper::Property::Lookup

        #
        # The namespace the migrations will be defined under.
        #
        # @return [String, nil]
        #   The namespace or `nil` if migrations are being defined
        #   in {Kernel}.
        #
        # @since 1.0.1
        #
        def migration_namespace
          @migration_namespace ||= unless self.name == 'Kernel'
                                     DataMapper::NamingConventions::Resource::Underscored.call(self.name)
                                   else
                                     nil
                                   end
        end

        #
        # The defined migrations.
        #
        # @return [Hash{Gem::Version => Array<Migration>}]
        #   The defined migrations grouped by version.
        #
        # @since 1.0.1
        #
        def migrations
          @migrations ||= Hash.new { |hash,key| hash[key] = [] }
        end

        #
        # Defines a new migration.
        #
        # @param [Symbol, String, Integer] position_or_version
        #   The migration position or a version the migration belongs to.
        #
        # @param [Symbol, String] name
        #   The name of the migration.
        #
        # @param [Hash] options
        #   Additional options for the migration.
        #
        # @option options [Symbol] :database
        #   Which DataMapper repository the migration will be ran on.
        #
        # @option options [Boolean] :verbose
        #   Specifies whether the migration will print status messages
        #   when ran.
        #
        # @yield []
        #   The given block will define the migration.
        #
        # @return [true]
        #   The migration was successfully defined.
        #
        # @raise [ArgumentError]
        #   Neither a `Symbol`, `String` or `Integer` was given for the
        #   `position_or_version` argument.
        #
        # @raise [RuntimeError]
        #   Another migration was previously defined with the same name.
        #
        # @example Migration defined with a position
        #   migration(1, :create_people_table) do
        #     up do
        #       create_table :people do
        #         column :id,   Integer, :serial => true
        #         column :name, String, :size => 50
        #         column :age,  Integer
        #       end
        #     end
        #
        #     down do
        #       drop_table :people
        #     end
        #   end
        #
        # @example Migration defined with a version
        #   migration('0.1.0', :create_people_table) do
        #     up do
        #       create_table :people do
        #         column :id,   Integer, :serial => true
        #         column :name, String, :size => 50
        #         column :age,  Integer
        #       end
        #     end
        #
        #     down do
        #       drop_table :people
        #     end
        #   end
        #
        # @note
        #   Its recommended that you stick with raw SQL for migrations that
        #   manipulate data. If you write a migration using a model, then
        #   later change the model, there's a possibility the migration
        #   will no longer work. Using SQL will always work.
        #
        # @since 1.0.1
        #
        def migration(position_or_version,name,options={},&block)
          target_version, target_position = migration_target(position_or_version)

          if (target_version.nil? && target_position.nil?)
            raise(ArgumentError,"Must specify either a version or migration position",caller)
          end

          unless target_version.version == '0.0.0'
            name = "#{target_version}-#{name}"
          end

          if self.migration_namespace
            # prefix the migration name with the migration namespace
            name = "#{self.migration_namespace}-#{name}"
          end

          if self.migrations[target_version].any? { |m| m.name == name }
            raise(RuntimeError,"Migration name conflict: #{name.dump}",caller)
          end

          self.migrations[target_version] << Migration.new(
            target_position,
            name,
            options,
            &block
          )
          return true
        end

        #
        # Migrates the database upward to a given position or version.
        #
        # @param [Symbol, String, Integer, nil] position_or_version
        #   The position or version to migrate the database to.
        #
        # @return [true]
        #   The database was successfully migrated up.
        #
        # @since 1.0.1
        #
        def migrate_up!(position_or_version=nil)
          target_version, target_position = migration_target(position_or_version)

          self.migrations.sort.each do |version,version_migrations|
            if (target_version.nil? || target_version <= version)
              version_migrations.each do |migration|
                if (target_position.nil? || target_position <= migration.position)
                  migration.perform_up
                end
              end
            end
          end

          return true
        end

        #
        # Migrates the database downwards to a certain position or version.
        #
        # @param [Symbol, String, Integer, nil] position_or_version
        #   The position or vesion to migrate the database down to.
        #
        # @return [true]
        #   The database was successfully migrated down.
        #
        # @since 1.0.1
        #
        def migrate_down!(position_or_version=nil)
          target_version, target_position = migration_target(position_or_version)

          self.migrations.sort.reverse_each do |version,version_migrations|
            if (target_version.nil? || version > target_version)
              version_migrations.reverse_each do |migration|
                if (target_position.nil? || migration.position > target_position)
                  migration.perform_down
                end
              end
            end
          end
        end

        private

        #
        # Converts a position or version into a version and position pair.
        #
        # @param [Symbol, String, Integer] position_or_version
        #   The migration position or version.
        #
        # @return [Array<Gem::Version, Integer>]
        #   The migration version and position.
        #
        # @since 1.0.1
        #
        def migration_target(position_or_version)
          case position_or_version
          when Symbol, String
            target_version = Gem::Version.new(position_or_version.to_s)
            target_position = self.migrations[target_version].length
          when Integer
            target_version = Gem::Version.new('0.0.0')
            target_position = position_or_version
          else
            target_version = nil
            target_position = nil
          end

          [target_version, target_position]
        end
      end
    end
  end
end
