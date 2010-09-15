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
  erb :project
end

get '/project/:guid/feature/:feature' do |guid,feature|
  Project.first(:guid => guid).feature(feature)
end

post '/project/:guid/feature/:feature' do |guid,feature_name|
  Project.first(:guid => guid).feature(feature_name).update(params[:text])
  redirect "/project/#{guid}/features"
end

get '/project/:guid/features' do |guid|
  project = Project.first(:guid => guid)
  project.features.inject("") do |result,feature_name|
    feature = project.feature(feature_name)
    result += <<EOF
      <form method='post' action='/project/#{guid}/feature/#{feature.name}'>
        <label for='#{feature.name}'>#{feature.name.humanize}</label><br/>
        <textarea name='text' id='#{feature.name}' class='feature' style='height:200px;width:700px;' >#{feature.to_s}</textarea>
        <input type='submit' value='Save'/>
      </form>
      <div>
        #{feature.result}
      </div>
EOF
  end
end

# This is fairly dangerous because you could send project/234/destroy
# It's also pretty freaking awesome
get '/project/:guid/:attribute' do |guid,attribute|
  Project.first(:guid => guid).send(attribute)
end
