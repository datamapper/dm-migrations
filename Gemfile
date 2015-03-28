source 'https://rubygems.org'

gemspec

DM_VERSION     = '~> 1.3.0.beta'
DO_VERSION     = '~> 0.10.15'
DM_DO_ADAPTERS = %w[sqlite postgres mysql oracle sqlserver]
GIT_BRANCH     = ENV.fetch('GIT_BRANCH', 'master')

gem 'dm-core', DM_VERSION, github: 'datamapper/dm-core', branch: GIT_BRANCH

group :datamapper do
  adapters = ENV['ADAPTER'] || ENV['ADAPTERS']
  adapters = adapters.to_s.tr(',', ' ').split.uniq - %w[in_memory]

  if (do_adapters = DM_DO_ADAPTERS & adapters).any?
    do_options = {}
    do_options[:github] = 'datamapper/do' if ENV['DO_GIT'] == 'true'

    gem 'data_objects', DO_VERSION, do_options.dup

    do_adapters.each do |adapter|
      adapter = 'sqlite3' if adapter == 'sqlite'
      gem "do_#{adapter}", DO_VERSION, do_options.dup
    end

    gem 'dm-do-adapter', DM_VERSION, github: 'datamapper/dm-do-adapter', branch: GIT_BRANCH
  end

  adapters.each do |adapter|
    gem "dm-#{adapter}-adapter", DM_VERSION, github: "datamapper/dm-#{adapter}-adapter", branch: GIT_BRANCH
  end

  plugins = ENV['PLUGINS'] || ENV['PLUGIN']
  plugins = plugins.to_s.tr(',', ' ').split

  plugins.each do |plugin|
    gem plugin, DM_VERSION, github: "datamapper/#{plugin}", branch: GIT_BRANCH
  end
end
