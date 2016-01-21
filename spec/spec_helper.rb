$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../lib')
plugin_test_dir = File.dirname(__FILE__)


require 'active_record'
if ActiveRecord::VERSION::STRING >= "3"
  require 'logger'
else
 # Workaround for https://rails.lighthouseapp.com/projects/8994/tickets/2577-when-using-activerecordassociations-outside-of-rails-a-nameerror-is-thrown
 ActiveRecord::ActiveRecordError
end

require plugin_test_dir + '/../init.rb'

ActiveRecord::Base.logger = Logger.new(plugin_test_dir + "/test.log")

ActiveRecord::Base.configurations = YAML::load(IO.read(plugin_test_dir + "/db/database.yml"))
ActiveRecord::Base.establish_connection(:sqlite3mem)
ActiveRecord::Migration.verbose = false
load(File.join(plugin_test_dir, "db", "schema.rb"))

Dir["#{plugin_test_dir}/models/*.rb"].each {|file| require file }

RSpec.configure do |config|

  config.expect_with(:rspec) { |c| c.syntax = :should }

  config.before do
  end
end

class ActiveRecord::Base

  # Compatibility method for AR 2.3.x and AR 3.2.x
  def get_error attr
    if errors.respond_to?(:on)
      errors.on(attr)
    else
      errors[attr].try(:first)
    end
  end
end

def ar2?
  ActiveRecord::VERSION::STRING < '3'
end

def ar4?
  ActiveRecord::VERSION::STRING >= '4'
end