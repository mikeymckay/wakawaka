require 'rubygems'
require 'sinatra'
require 'json'
require 'friendly'

Friendly.configure(YAML::load_file("config/database.yml")['test'])

# Reset the test database
#File.delete(Friendly.db.opts[:database]) if Friendly.db.opts[:adapter] == "sqlite"
`rm -rf #{File.dirname(Friendly.db.opts[:database])}/*`

# Set test environment
Sinatra::Application.set :environment, :test
Sinatra::Application.set :run, false
Sinatra::Application.set :raise_errors, true
Sinatra::Application.set :logging, false

require File.join(File.dirname(__FILE__), '..', 'models','project')
require File.join(File.dirname(__FILE__), '..', 'application')

require 'spec'
require 'spec/interop/test'
require 'rack/test'
require 'mocha'
require 'factory_girl'

Friendly.create_tables!

Spec::Runner.configure do |config|
  config.mock_with(:mocha)
  config.before(:each) do
    # Reset database before each example is run, or rescue if no transaction is active
    Friendly.db.execute "ROLLBACK" rescue nil
    Friendly.db.execute "BEGIN"
  end
end
