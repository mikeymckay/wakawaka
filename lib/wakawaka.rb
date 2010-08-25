require 'rubygems'
require 'sinatra'
require 'git'
require 'uuid'
require 'json'
require 'friendly'

ROOT = File.expand_path(File.dirname(__FILE__) + "/../") + "/"

# Configure the database
Friendly.configure(YAML::load_file("database.yml")[Sinatra::Base.environment.to_s])

#require 'sinatra/base'

class Project 
  include Friendly::Document
  attribute :name, String
  attribute :git_uri, String
  attribute :data_dir, String
  attribute :processing_message, String
  attribute :last_commit_author, String
  attribute :last_commit_message, String
  attribute :last_commit_date, String
  attribute :scenarios, String
  attribute :steps, String
  attribute :json, String
  attribute :error, String
  attribute :deleted, Friendly::Boolean, :default => false

  indexes :deleted

  def self.clone(name,git_uri,save_path)
#    create_project(id, {:git_uri => git_uri, :name => name, processing_message => true})

    project = Project.new
    project.name = name
    project.git_uri = git_uri
    project.processing_message = "Processing git clone"
    project.save

    project.data_dir = save_path + project.id

    fork do
      begin
        Git.clone(git_uri, project.data_dir)
      rescue Exception => e
#        append_property_to_project(id, :error => e)
        project.error = e
        project.save
      end
      project.last_commit
      #remove_property_from_project(id,processing_message)
      project.processing_message = nil
      project.save
    end
    project
  end

  def pull
    self.processing_message = "Processing git pull"
    self.save
    fork do
      Git.open(self.data_dir).pull
      last_commit
      #remove_property_from_project(id,processing_message)
      self.processing_message = nil
      self.save
    end
  end

  def last_commit
    #last_commit = Git.open(data_dir+id).log.first rescue nil || false
    last_commit = Git.open(self.data_dir).log.first
    self.last_commit_author = last_commit.author.name,
    self.last_commit_message = last_commit.message,
    self.last_commit_date = last_commit.date
    self.save
  end

  def process_features
    self.processing_message = "Processing cucumber specifications"
    self.scenarios = nil
    self.steps = nil
    self.save
    fork do
      cucumber_results = `cd #{self.data_dir};cucumber`
      self.scenarios = cucumber_results.match(/^\d+ scenario.*/)[0],
      self.steps = cucumber_results.match(/^\d+ step.*/)[0]
      self.processing_message = nil
      self.save
    end
  end

  def update
    self.pull
    self.features
  end

  def all
  end

end

# Create and auto-migrate the tables
Friendly.create_tables!

class Wakawaka < Sinatra::Base
  set :public, 'public'

  configure do
  end

  def yell(msg)
    # Stupid simple logging
    File.open("#{ROOT}log/yell.log","a") do |file|
      file.puts "[#{Time.now}] #{msg}"
    end
  end

  def view_project_info(project)
    @project = project
    erb <<EOF
      <a href='/project/<%=@project.id%>'><%=@project.name%></a>
      <small>
        <pre><%= @data.to_yaml %></pre>
      </small>
EOF
  end

  get '/' do
    erb :home
  end

  get '/projects' do
    @projects = Project.all(:deleted => false)
    erb <<EOF
      <% @projects.each do |project| %>
        <li>
          <%= view_project_info(project) %>
        </li> 
      <% end %>
EOF
  end

  post '/new_project' do
    data_dir = ROOT + settings.environment.to_s + "_data" + "/"
    project = Project.clone(params[:name],params[:git_uri], data_dir)
    project.process_features
  end

  get '/project/:id' do |id|
    Project.find(id).update
    @id=id
    erb :project
  end

  get '/project_info/:id' do |id|
    view_project_info(Project.find(id))
  end

end
