require 'spec_helper'

require 'dm-migrations/auto_migration'

describe DataMapper::Migrations do
  def capture_log(mod)
    original, mod.logger = mod.logger, DataObjects::Logger.new(@log = StringIO.new, :debug)
    yield
  ensure
    @log.rewind
    @output = @log.readlines.map do |line|
      line.chomp.gsub(/\A.+?~ \(\d+\.?\d*\)\s+/, '')
    end

    mod.logger = original
  end

  supported_by :postgres do
    before :all do
      module ::Blog
        class Article
          include DataMapper::Resource

          property :id, Serial
        end
      end

      @model = ::Blog::Article
    end

    describe '#auto_upgrade' do
      it 'should create an index' do
        @model.auto_migrate!
        @property = @model.property(:name, String, :index => true)
        @response = capture_log(DataObjects::Postgres) { @model.auto_upgrade! }
        @output[-2].should == "CREATE INDEX \"index_blog_articles_name\" ON \"blog_articles\" (\"name\")"
      end
    end
  end
end
