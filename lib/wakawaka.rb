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

  def project_info(id)
    @id = id
    @data = projects[id]
    erb <<EOF
      <a href='/project/<%=@id%>'><%=@data[:name]%></a>
      <small>
        <%= @data[:git_uri] %> 
        <% last_commit = Git.open(data_dir+@id).log.first rescue nil || false%>
        <% if last_commit %>
          <%= last_commit.author.name %>
          <%= last_commit.message %>
          <%= last_commit.date %>
          Status: <%= @data[:git_uri]%>
        <% elsif @data[:error]%>
          Error: <pre><%= @data[:error].to_yaml %></pre>
        <% else %>
          Loading git data...
        <% end %>
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
    name = params[:name]
    project_id = name.gsub(/[^a-zA-Z]/,"") + "-" + UUID.generate
    git_uri = params[:git_uri]
    new_projects = projects
    new_projects[project_id] = {:git_uri => git_uri, :name => name}
    File.open(data_dir + "projects.yml","w+") do |file|
      file.puts new_projects.to_yaml
    end
    fork do
      begin
        Git.clone(git_uri, data_dir + project_id)
      rescue Exception => e
        new_projects = projects
        new_projects[project_id][:error] = e
        File.open(data_dir + "projects.yml","w+") do |file|
          file.puts new_projects.to_yaml
        end
      end
    end
  end

  get '/project/:clone_path' do |clone_path|
    project_info(clone_path)
  end

end
