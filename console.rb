require 'rubygems'
require 'json'
require 'friendly'

# Configure the database
Friendly.configure(YAML::load_file("config/database.yml")['development'])

require 'models/project.rb'

