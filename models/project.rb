require 'rubygems'
require 'json'
require 'friendly'
require 'git'
require 'nokogiri'

# Need this line to be run when using this
#Friendly.configure(YAML::load_file("config/database.yml")["development"])

class Feature
  def initialize(path_to_feature_file)
    raise Exception unless File.exists? path_to_feature_file
    @file = path_to_feature_file
  end

  def self.load(path_to_feature_file)
    self.new(path_to_feature_file)
  end

  def project_path
    # two levels above where the feature file is
    File.dirname(File.dirname(@file))
  end

  def file_name
    File.basename(@file)
  end

  def result
    full_result = `cd #{project_path};cucumber --format html features/#{file_name}`
    html_page = Nokogiri::HTML(full_result)
    html_page.css("div#cucumber-header").unlink
    html_page.css("head style").to_html.gsub(/absolute/,"block").gsub(/body.*?\}/m,"").gsub(/.cucumber, td, th.*?\}/m,"") +  html_page.css("div.cucumber").to_html
  end

  def to_s
    File.read(@file)
  end

  def update(text)
    File.open(@file,"w") do |file|
      file.puts text
    end
  end

  def name
    self.file_name.gsub(/\.feature/,"")
  end
end

class Project 
  include Friendly::Document
  attribute :name, String
  attribute :guid, String
  attribute :git_uri, String
  attribute :available_branches, String
  attribute :current_branch, String
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
        git_project = Git.clone(git_uri, project.data_dir)
        # branches list should consist of list of local branches only
        project.available_branches = git_project.branches.map{|branch| branch.name unless branch.remote}.compact.join(", ")
        project.current_branch = "master"
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

  def to_html
    "
    <a href='#{url}'>#{name}</a>
    <a class='delete_project' href='#{url}/delete'>Delete</a>

    <table id ='table_#{guid}'>" + \
    self.to_hash.reject{|key,value|
      #remove unwanted keys
      [ :cucumber_results,
        :id,
        :deleted
      ].include? key 
    }.sort{|a,b|
      a[0].to_s <=> b[0].to_s # sort based on the key
    }.inject(""){|result, element| 
      # Create links and reformat elements
      property = element[0].to_s
      value = element[1].to_s
      value = "<a href='#{url}/features'>#{value}</a>" if property.match(/scenario|steps/i)
      value = "<a href='#{github_url}/features'>#{value}</a>" if property.match(/git_uri/) and github_url
      if property.match(/available_branches/)
        value = value.split(",").map{|branch|"<a href='#{url}/checkout/#{branch}'>#{branch}</a>"}.join(", ")
      end

      "#{result}
      <tr>
        <td>#{ActiveSupport::Inflector.humanize(property)}</td>
        <td> #{value}</td>
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

  def features_dir
    self.data_dir+"/features/"
  end

  def features
    Dir.glob(self.features_dir+"*.feature").map do |file|
      File.basename file.gsub(/\.feature/,"")
    end
  end

  def feature(name)
    Feature.load(self.features_dir + name + ".feature")
  end

  def checkout(branch_name = 'master')
    Git.open(self.data_dir).checkout(branch_name)
  end

end

# This is non destructive so we can just run it every time
Friendly.create_tables!
