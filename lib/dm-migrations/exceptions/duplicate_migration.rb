module DataMapper
  module Migrations
    class DuplicateMigration < StandardError

      def initialize(migration)
        super("Duplicate Migration Name: '#{migration.name}', version: #{migration.position}")
      end

    end
  end
end
