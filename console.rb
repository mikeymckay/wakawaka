#!/usr/bin/ruby
require 'rubygems'
require 'json'
require 'friendly'

# Configure the database
Friendly.configure(YAML::load_file("config/database.yml")['development'])
#Friendly.configure(YAML::load_file("config/database.yml")['test'])

require 'models/project.rb'
