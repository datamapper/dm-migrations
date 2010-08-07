require 'dm-migrations/runner'

# The top-level DataMapper migration runner
DataMapper::MigrationRunner = DataMapper::Migrations::Runner

module Kernel
  include DataMapper::Migrations::Runner
end
