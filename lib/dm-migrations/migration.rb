require 'dm-migrations/exceptions/duplicate_migration'
require 'dm-migrations/sql'

require 'set'
require 'benchmark'

module DataMapper
  class Migration
    include SQL

    # The name of the migration
    attr_reader :name

    # The repository the migration operates on
    attr_reader :repository

    # The dependencies of the migration
    attr_reader :needs

    # The adapter the migration is operating on
    attr_reader :adapter

    #
    # Creates a new migration.
    #
    # @param [Symbol] name
    #   The name of the migration.
    #
    # @param [Hash] options
    #   Additional options for the migration.
    #
    # @option options [Boolean] :verbose (true)
    #   Enables or disables verbose output.
    #
    # @option options [Symbol] :repository (:default)
    #   The DataMapper repository the migration will operate on.
    #
    # @option options [Array, Symbol] :needs ([])
    #   Other migrations that are dependencies of the migration.
    #
    # @api semipublic
    #
    def initialize(name, options = {}, &block)
      @name       = name
      @options    = options
      @repository = :default

      if options.has_key?(:database)
        warn "Using the :database option with migrations is deprecated, use :repository instead"

        @repository = options[:database]
      elsif options.has_key?(:repository)
        @repository = options[:repository]
      end

      @verbose     = options.fetch(:verbose, true)
      @needs       = Set[*options.fetch(:needs, [])]
      @up_action   = nil
      @down_action = nil

      instance_eval(&block)
    end

    # define the actions that should be performed on an up migration
    def up(&block)
      @up_action = block
    end

    # define the actions that should be performed on a down migration
    def down(&block)
      @down_action = block
    end

    # perform the migration by running the code in the #up block
    def perform_up
      result = nil

      setup! unless setup?

      if needs_up?
        # TODO: fix this so it only does transactions for databases that support create/drop
        # database.transaction.commit do
        if @up_action
          say_with_time "== Performing Up Migration: #{name}", 0 do
            result = @up_action.call
          end
        end

        update_migration_info(:up)
        # end
      end

      result
    end

    # un-do the migration by running the code in the #down block
    def perform_down
      result = nil

      setup! unless setup?

      if needs_down?
        # TODO: fix this so it only does transactions for databases that support create/drop
        # database.transaction.commit do
        if @down_action
          say_with_time "== Performing Down Migration: #{name}", 0 do
            result = @down_action.call
          end
        end

        update_migration_info(:down)
        # end
      end

      result
    end

    # execute raw SQL
    def execute(sql, *bind_values)
      say_with_time(sql) do
        @adapter.execute(sql, *bind_values)
      end
    end

    def create_table(table_name, opts = {}, &block)
      execute TableCreator.new(@adapter, table_name, opts, &block).to_sql
    end

    def drop_table(table_name, opts = {})
      execute "DROP TABLE #{@adapter.send(:quote_name, table_name.to_s)}"
    end

    def modify_table(table_name, opts = {}, &block)
      TableModifier.new(@adapter, table_name, opts, &block).statements.each do |sql|
        execute(sql)
      end
    end

    def create_index(table_name, *columns_and_options)
      if columns_and_options.last.is_a?(Hash)
        opts = columns_and_options.pop
      else
        opts = {}
      end
      columns = columns_and_options.flatten

      opts[:name] ||= "#{opts[:unique] ? 'unique_' : ''}index_#{table_name}_#{columns.join('_')}"

      execute <<-SQL.compress_lines
        CREATE #{opts[:unique] ? 'UNIQUE ' : '' }INDEX #{quote_column_name(opts[:name])} ON
        #{quote_table_name(table_name)} (#{columns.map { |c| quote_column_name(c) }.join(', ') })
      SQL
    end

    # Output some text. Optional indent level
    def say(message, indent = 4)
      write "#{" " * indent} #{message}"
    end

    # Time how long the block takes to run, and output it with the message.
    def say_with_time(message, indent = 2)
      say(message, indent)
      result = nil
      time = Benchmark.measure { result = yield }
      say("-> %.4fs" % time.real, indent)
      result
    end

    # output the given text, but only if verbose mode is on
    def write(text = "")
      puts text if @verbose
    end

    # Inserts or removes a row into the `migration_info` table, so we can mark this migration as run, or un-done
    def update_migration_info(direction)
      save, @verbose = @verbose, false

      create_migration_info_table_if_needed

      if direction.to_sym == :up
        execute("INSERT INTO #{migration_info_table} (#{migration_name_column}) VALUES (#{quoted_name})")
      elsif direction.to_sym == :down
        execute("DELETE FROM #{migration_info_table} WHERE #{migration_name_column} = #{quoted_name}")
      end
      @verbose = save
    end

    def create_migration_info_table_if_needed
      save, @verbose = @verbose, false
      unless migration_info_table_exists?
        execute("CREATE TABLE #{migration_info_table} (#{migration_name_column} VARCHAR(255) UNIQUE)")
      end
      @verbose = save
    end

    # Quote the name of the migration for use in SQL
    def quoted_name
      "'#{name}'"
    end

    def migration_info_table_exists?
      adapter.storage_exists?('migration_info')
    end

    # Fetch the record for this migration out of the migration_info table
    def migration_record
      return [] unless migration_info_table_exists?
      @adapter.select("SELECT #{migration_name_column} FROM #{migration_info_table} WHERE #{migration_name_column} = #{quoted_name}")
    end

    # True if the migration needs to be run
    def needs_up?
      return true unless migration_info_table_exists?
      migration_record.empty?
    end

    # True if the migration has already been run
    def needs_down?
      return false unless migration_info_table_exists?
      ! migration_record.empty?
    end

    # Quoted table name, for the adapter
    def migration_info_table
      @migration_info_table ||= quote_table_name('migration_info')
    end

    # Quoted `migration_name` column, for the adapter
    def migration_name_column
      @migration_name_column ||= quote_column_name('migration_name')
    end

    def quote_table_name(table_name)
      # TODO: Fix this for 1.9 - can't use this hack to access a private method
      @adapter.send(:quote_name, table_name.to_s)
    end

    def quote_column_name(column_name)
      # TODO: Fix this for 1.9 - can't use this hack to access a private method
      @adapter.send(:quote_name, column_name.to_s)
    end

    protected

    #
    # Determines whether the migration has been setup.
    #
    # @return [Boolean]
    #   Specifies whether the migration has been setup.
    #
    # @since 1.0.1
    #
    def setup?
      !@adapter.nil?
    end

    #
    # Sets up the migration.
    #
    # @since 1.0.1
    #
    def setup!
      @adapter = DataMapper.repository(@repository).adapter

      case @adapter.class.name
      when /Sqlite/   then @adapter.extend(SQL::Sqlite)
      when /Mysql/    then @adapter.extend(SQL::Mysql)
      when /Postgres/ then @adapter.extend(SQL::Postgres)
      else
        raise(RuntimeError, "Unsupported Migration Adapter #{@adapter.class}", caller)
      end
    end
  end
end
