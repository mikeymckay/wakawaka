require 'rubygems'
require 'sinatra'
require 'git'
require 'uuid'

ROOT = File.expand_path(File.dirname(__FILE__) + "/../") + "/"

#require 'sinatra/base'

class Wakawaka < Sinatra::Base
  set :public, 'public'

  def yell(msg)
    # Stupid simple logging
    File.open("#{ROOT}log/yell.log","a") do |file|
      file.puts "[#{Time.now}] #{msg}"
    end
  end

  def data_dir
    ROOT + settings.environment.to_s + "_data" + "/"
  end

  def projects
    YAML.load_file(data_dir + "projects.yml") rescue nil || {}
  end

  def create_project(id,hash)
    projects_updated = projects
    projects_updated[id] = hash
    File.open(data_dir + "projects.yml","w+") do |file|
      file.puts projects_updated.to_yaml
    end
  end

  def append_property_to_project(id,hash)
    projects_updated = projects
    projects_updated[id].merge!(hash)
    File.open(data_dir + "projects.yml","w+") do |file|
      file.puts projects_updated.to_yaml
    end
  end

  def remove_property_from_project(id,property)
    projects_updated = projects
    projects_updated[id].delete(property)
    File.open(data_dir + "projects.yml","w+") do |file|
      file.puts projects_updated.to_yaml
    end
  end

  def clone(name,git_uri)
    processing_message = "Processing git clone"
    id = name.gsub(/[^a-zA-Z]/,"") + "-" + UUID.generate
    create_project(id, {:git_uri => git_uri, :name => name, processing_message => true})
    fork do
      begin
        Git.clone(git_uri, data_dir + id)
      rescue Exception => e
        append_property_to_project(id, :error => e)
      end
      last_commit(id)
      remove_property_from_project(id,processing_message)
    end
    return id
  end

  def pull(id)
    processing_message = "Processing git pull"
    append_property_to_project(id,{processing_message => Time.now})
    fork do
      projects_updated = projects
      Git.open(data_dir+id).pull
      last_commit(id)
      remove_property_from_project(id,processing_message)
    end
  end

  def last_commit(id)
    last_commit = Git.open(data_dir+id).log.first
    #last_commit = Git.open(data_dir+id).log.first rescue nil || false
    append_property_to_project(id, {
      :last_commit_author => last_commit.author.name,
      :last_commit_message => last_commit.message,
      :last_commit_date => last_commit.date
    })
  end

  def cucumber(id)
    processing_message = "Processing cucumber specifications"
    append_property_to_project(id,{processing_message => Time.now})
    remove_property_from_project(id,:scenarios)
    remove_property_from_project(id,:steps)
    fork do
      cucumber_results = `cd #{data_dir}#{id};cucumber`
      append_property_to_project(id, {
        :scenarios => cucumber_results.match(/^\d+ scenario.*/)[0],
        :steps => cucumber_results.match(/^\d+ step.*/)[0]
      })
      remove_property_from_project(id,processing_message)
    end
  end

  def update(id)
    pull(id)
    cucumber(id)
  end

  def project_info(id)
    @id = id
    @data = projects[id]
    erb <<EOF
      <a href='/project/<%=@id%>'><%=@data[:name]%></a>
      <small>
        <pre><%= @data.to_yaml %></pre>
      </small>
EOF
  end

  get '/' do
    erb :home
  end

  get '/projects' do
    erb <<EOF
      <% projects.keys.each do |project| %>
        <li>
          <%= project_info(project) %>
        </li> 
      <% end %>
EOF
  end

  post '/new_project' do
    id = clone(params[:name],params[:git_uri])
    cucumber(id)
  end

  get '/project/:id' do |id|
    update(id)
    @id=id
    erb :project
  end

  get '/project_info/:id' do |id|
    project_info(id)
  end

end
