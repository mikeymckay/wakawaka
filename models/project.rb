require 'rubygems'
require 'json'
require 'friendly'
require 'git'

# Need this line to be run when using this
#Friendly.configure(YAML::load_file("config/database.yml")["development"])

class Project 
  include Friendly::Document
  attribute :name, String
  attribute :guid, String
  attribute :git_uri, String
  attribute :data_dir, String
  attribute :processing_message, String
  attribute :last_commit_author, String
  attribute :last_commit_message, String
  attribute :last_commit_date, String
  attribute :scenarios, String
  attribute :steps, String
  attribute :error, String
  attribute :deleted, Friendly::Boolean, :default => false
  attribute :cucumber_results, String

  indexes :deleted
  indexes :guid

  def self.clone(name, git_uri)
    project = Project.new
    project.name = name
    project.git_uri = git_uri
    project.processing_message = "Processing git clone"
    project.guid = project.id.to_guid
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
      self.cucumber_results = `cd #{self.data_dir};cucumber --format html`
      self.scenarios = self.cucumber_results.match(/\d+ scenario.*?\)/)[0]
      self.steps = self.cucumber_results.match(/\d+ step.*?\)/)[0]
      self.processing_message = nil
      self.save
#    end
  end

  def update
    self.pull
    self.process_features
  end

  def to_html_table
    "<table id ='table_#{self.guid}'>" + \
    self.to_hash.reject{|key,value|
      #remove unwanted keys
      [ :cucumber_results,
        :id,
        :deleted
      ].include? key 
    }.sort{|a,b|
      a[0].to_s <=> b[0].to_s # sort based on the key
    }.inject(""){|result, element| 
      "#{result}
      <tr>
        <td>#{ActiveSupport::Inflector.humanize(element[0])}</td>
        <td> #{element[1]}</td>
      </tr>
      "
    } + "</table>"
  end

  def url
    return "/project/#{self.guid}"
  end

  def github_url
    "http://" + git_uri.match(/(github.com.*)\.git/)[1] rescue nil
  end

  # This would be nicer if we used cucumber formatters
  def cucumber_results_tweaked
    self.cucumber_results.gsub(/<div id="label">(.*?)<\/div>/){ |match|
      "<div id=\"label\">#{$1}<a href='#{self.url}'>Back</a><a href='#{self.github_url}'>Edit Scenarios</a><\/div>"
    }
  end

end

# This is non destructive so we can just run it every time
Friendly.create_tables!
