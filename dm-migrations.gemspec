# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{dm-migrations}
  s.version = "1.1.0.rc2"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["Paul Sadauskas"]
  s.date = %q{2011-03-06}
  s.description = %q{DataMapper plugin for writing and speccing migrations}
  s.email = %q{psadauskas [a] gmail [d] com}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = [
    "Gemfile",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "VERSION",
    "db/migrations/1_create_people_table.rb",
    "db/migrations/2_add_dob_to_people.rb",
    "db/migrations/config.rb",
    "dm-migrations.gemspec",
    "examples/sample_migration.rb",
    "examples/sample_migration_spec.rb",
    "lib/dm-migrations.rb",
    "lib/dm-migrations/adapters/dm-do-adapter.rb",
    "lib/dm-migrations/adapters/dm-mysql-adapter.rb",
    "lib/dm-migrations/adapters/dm-oracle-adapter.rb",
    "lib/dm-migrations/adapters/dm-postgres-adapter.rb",
    "lib/dm-migrations/adapters/dm-sqlite-adapter.rb",
    "lib/dm-migrations/adapters/dm-sqlserver-adapter.rb",
    "lib/dm-migrations/adapters/dm-yaml-adapter.rb",
    "lib/dm-migrations/auto_migration.rb",
    "lib/dm-migrations/exceptions/duplicate_migration.rb",
    "lib/dm-migrations/migration.rb",
    "lib/dm-migrations/migration_runner.rb",
    "lib/dm-migrations/sql.rb",
    "lib/dm-migrations/sql/column.rb",
    "lib/dm-migrations/sql/mysql.rb",
    "lib/dm-migrations/sql/postgres.rb",
    "lib/dm-migrations/sql/sqlite.rb",
    "lib/dm-migrations/sql/table.rb",
    "lib/dm-migrations/sql/table_creator.rb",
    "lib/dm-migrations/sql/table_modifier.rb",
    "lib/spec/example/migration_example_group.rb",
    "lib/spec/matchers/migration_matchers.rb",
    "spec/integration/auto_migration_spec.rb",
    "spec/integration/auto_upgrade_spec.rb",
    "spec/integration/migration_runner_spec.rb",
    "spec/integration/migration_spec.rb",
    "spec/integration/sql_spec.rb",
    "spec/isolated/require_after_setup_spec.rb",
    "spec/isolated/require_before_setup_spec.rb",
    "spec/isolated/require_spec.rb",
    "spec/rcov.opts",
    "spec/spec.opts",
    "spec/spec_helper.rb",
    "spec/unit/migration_spec.rb",
    "spec/unit/sql/column_spec.rb",
    "spec/unit/sql/postgres_spec.rb",
    "spec/unit/sql/sqlite_extensions_spec.rb",
    "spec/unit/sql/table_creator_spec.rb",
    "spec/unit/sql/table_modifier_spec.rb",
    "spec/unit/sql/table_spec.rb",
    "spec/unit/sql_spec.rb",
    "tasks/spec.rake",
    "tasks/yard.rake",
    "tasks/yardstick.rake"
  ]
  s.homepage = %q{http://github.com/datamapper/dm-migrations}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{datamapper}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{DataMapper plugin for writing and speccing migrations}
  s.test_files = [
    "examples/sample_migration.rb",
    "examples/sample_migration_spec.rb",
    "spec/integration/auto_migration_spec.rb",
    "spec/integration/auto_upgrade_spec.rb",
    "spec/integration/migration_runner_spec.rb",
    "spec/integration/migration_spec.rb",
    "spec/integration/sql_spec.rb",
    "spec/isolated/require_after_setup_spec.rb",
    "spec/isolated/require_before_setup_spec.rb",
    "spec/isolated/require_spec.rb",
    "spec/spec_helper.rb",
    "spec/unit/migration_spec.rb",
    "spec/unit/sql/column_spec.rb",
    "spec/unit/sql/postgres_spec.rb",
    "spec/unit/sql/sqlite_extensions_spec.rb",
    "spec/unit/sql/table_creator_spec.rb",
    "spec/unit/sql/table_modifier_spec.rb",
    "spec/unit/sql/table_spec.rb",
    "spec/unit/sql_spec.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<dm-core>, ["~> 1.1.0.rc2"])
      s.add_development_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_development_dependency(%q<rake>, ["~> 0.8.7"])
      s.add_development_dependency(%q<rspec>, ["~> 1.3.1"])
    else
      s.add_dependency(%q<dm-core>, ["~> 1.1.0.rc2"])
      s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
      s.add_dependency(%q<rake>, ["~> 0.8.7"])
      s.add_dependency(%q<rspec>, ["~> 1.3.1"])
    end
  else
    s.add_dependency(%q<dm-core>, ["~> 1.1.0.rc2"])
    s.add_dependency(%q<jeweler>, ["~> 1.5.2"])
    s.add_dependency(%q<rake>, ["~> 0.8.7"])
    s.add_dependency(%q<rspec>, ["~> 1.3.1"])
  end
end

