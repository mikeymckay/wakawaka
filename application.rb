require 'rubygems'
require 'sinatra'

set :public, 'public'

APPLICATION_ROOT = File.expand_path(File.dirname(__FILE__))

def yell(msg)
  # Stupid simple logging
  File.open("#{APPLICATION_ROOT}log/yell.log","a") do |file|
    file.puts "[#{Time.now}] #{msg}"
  end
end

def view_project_info(project)
  @project = project
  erb <<EOF
    <a href='/project/<%=@project.readable_guid%>'><%=@project.name%></a>
    <small>
      <pre><%= @project.to_yaml.gsub(/.*was.*\n/,"") %></pre>
    </small>
EOF
end

get '/' do
  puts settings.environment
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
  project = Project.clone(params[:name],params[:git_uri])
  project.process_features
end

get '/project/:readable_guid' do |@readable_guid|
  Project.first(:readable_guid => @readable_guid).update
  "<a href='/'>Home</a>" + (erb :project)
end

get '/project_info/:readable_guid' do |readable_guid|
  view_project_info(Project.first(:readable_guid => readable_guid))
end

