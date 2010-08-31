require 'rubygems'
require 'json'
require 'friendly'
require 'git'

# Need this line to be run when using this
#Friendly.configure(YAML::load_file("config/database.yml")["development"])

class Project 
  include Friendly::Document
  attribute :name, String
  attribute :readable_guid, String
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
  indexes :readable_guid

  def self.clone(name, git_uri)
    project = Project.new
    project.name = name
    project.git_uri = git_uri
    project.processing_message = "Processing git clone"
    project.readable_guid = project.id.to_guid
    # Creates a human readable unique directory name
    project.data_dir = File.join(File.dirname(Friendly.db.opts[:database]),name.gsub(/([^A-Za-z])/,"")+"_"+project.id.to_guid)
    project.save

#    fork do
      begin
        Git.clone(git_uri, project.data_dir)
      rescue Exception => e
        project.error = e
        project.save
      end
      project.last_commit
      project.processing_message = nil
      project.save
#    end
    return project
  end

  def pull
    self.processing_message = "Processing git pull"
    self.save
#    fork do
      Git.open(self.data_dir).pull
      self.last_commit
      self.processing_message = nil
      self.save
#    end
  end

  def last_commit
    #last_commit = Git.open(data_dir+id).log.first rescue nil || false
    last_commit = Git.open(self.data_dir).log.first
    self.last_commit_author = last_commit.author.name
    self.last_commit_message = last_commit.message
    self.last_commit_date = last_commit.date
    self.save
  end

  def process_features
    self.processing_message = "Processing cucumber specifications"
    self.scenarios = nil
    self.steps = nil
    self.save
#    fork do
      cucumber_results = `cd #{self.data_dir};cucumber`
      self.scenarios = cucumber_results.match(/^\d+ scenario.*/)[0],
      self.steps = cucumber_results.match(/^\d+ step.*/)[0]
      self.processing_message = nil
      self.save
#    end
  end

  def update
    self.pull
    self.process_features
  end

end

# This is non destructive so we can just run it every time
Friendly.create_tables!
