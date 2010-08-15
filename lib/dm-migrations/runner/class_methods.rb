require 'dm-migrations/graph'
require 'dm-core'

module DataMapper
  module Migrations
    module Runner
      module ClassMethods
        include DataMapper::Property::Lookup

        #
        # The defined migrations.
        #
        # @return [Graph]
        #   The defined migrations.
        #
        # @since 1.0.1
        #
        # @api public
        #
        def migrations
          @migrations ||= DataMapper::Migrations::Graph.new
        end

        #
        # Defines a new migration.
        #
        # @param [Array] arguments
        #   Additional arguments.
        #
        # @yield []
        #   The given block will define the migration.
        #
        # @return [Migration]
        #   The newly defined migration.
        #
        # @raise [ArgumentError]
        #   The first argument was not a `Symbol`, `String` or `Integer`.
        #
        # @raise [DuplicateMigration]
        #   Another migration was previously defined with the same name or
        #   position.
        #
        # @example Defining a migration at a position
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
        # @example Defining a migration with a name
        #   migration(:create_people_table) do
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
        # @example Defining a migration with dependencies
        #   migration(:add_salary_column, :needs => :create_people_table) do
        #     up do
        #       modify_table :people do
        #         add_column :salary, Integer
        #       end
        #     end
        #
        #     down do
        #       modify_table :people do
        #         drop_column :salary
        #       end
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
        # @api public
        #
        def migration(*arguments,&block)
          case arguments[0]
          when Integer
            position = arguments[0]
            name = arguments[1]
            options = (arguments[2] || {})

            self.migrations.migration_at(position,name,options,&block)
          when Symbol, String
            name = arguments[0]
            options = (arguments[1] || {})

            self.migrations.migration_named(name,options,&block)
          else
            raise(ArgumentError,"first argument must be an Integer, Symbol or a String",caller)
          end
        end

        #
        # Migrates the database upward to a given migration position or name.
        #
        # @param [Symbol, Integer, nil] position_or_name
        #   The migration position or name to migrate the database to.
        #
        # @return [true]
        #   The database was successfully migrated up.
        #
        # @raise [UnknownMigration]
        #   A migration had a dependencey on an unknown migration.
        #
        # @since 1.0.1
        #
        # @api public
        #
        def migrate_up!(position_or_name=nil)
          self.migrations.up_to(position_or_name) do |migration|
            migration.perform_up
          end

          return true
        end

        #
        # Migrates the database downwards to a certain migration position or name.
        #
        # @param [Symbol, Integer, nil] position_or_name
        #   The migration position or name to migrate the database down to.
        #
        # @return [true]
        #   The database was successfully migrated down.
        #
        # @raise [UnknownMigration]
        #   A migration had a dependencey on an unknown migration.
        #
        # @since 1.0.1
        #
        # @api public
        #
        def migrate_down!(position_or_name=nil)
          self.migrations.down_to(position_or_name) do |migration|
            migration.perform_down
          end

          return true
        end
      end
    end
  end
end
