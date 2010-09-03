require 'rubygems'
require 'json'
require 'friendly'
require 'sinatra'

# Configure the database
Friendly.configure(YAML::load_file(File.join(File.dirname(__FILE__), "database.yml"))["development"])

set :public, 'public'
set :views, 'views'
set :environment, :development
#set :lock, true

require 'application'
require File.join(File.dirname(__FILE__), '../models/project.rb')

# Setup the logging
FileUtils.mkdir_p('log') unless File.exists?('log')
log = File.new("log/sinatra.log", "a")
$stdout.reopen(log)
$stderr.reopen(log)

run Sinatra::Application
