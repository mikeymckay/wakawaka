require 'rubygems'
require 'sinatra'

set :public, 'public'

APPLICATION_ROOT = File.expand_path(File.dirname(__FILE__)) + "/"

def yell(msg)
  # Stupid simple logging
  File.open("#{APPLICATION_ROOT}log/yell.log","a") do |file|
    file.puts "[#{Time.now}] #{msg}"
  end
end

get '/' do
  erb :home
end

get '/projects' do
  @projects = Project.all(:deleted => false)

  erb <<EOF
    <% @projects.each do |project| %>
        <a href='project/<%= project.guid %>'><%= project.name %></a>
        <small>
          <%= project.to_html_table %>
        </small
    <% end %>
EOF
end

post '/new_project' do
  project = Project.clone(params[:name],params[:git_uri])
  project.process_features
end

get '/project/:guid' do |guid|
  @project = Project.first(:guid => guid)
  erb "<a href='/'>Home</a> <%= @project.name%> 
  <div id='project_<%= @project.guid %>'>Loading...</ul>
  <script>
    $.get('<%= @project.url %>/update')
    $('#project_<%= @project.guid %>').load('<%= @project.url %>/to_html_table')
  </script>
  "
end

get '/project/:guid/:attribute' do |guid,attribute|
  Project.first(:guid => guid).send(attribute)
end
