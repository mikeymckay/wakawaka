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
  Project.all(:deleted => false).inject("") do |result,project|
    result += <<EOF
    <h3><a href='#{project.url}'>#{project.name}</a></h3>
    <div class='togglable' id='project_#{project.guid}'/>
    <script>
      $.get('#{project.url}/update');
      $('#project_#{project.guid}').load('#{project.url}?no_template=true');
    </script>
EOF
  end + <<EOF
    <script>
      $('.togglable').hide().siblings('h3').prepend('<span>[+]</span><span style="display:none">[-]</span>');
      //Slide up and down & toogle the Class on click
      $('.togglable').siblings("h3").click(function(){
        $(this).children().toggle();
        $(this).toggleClass('active').next().slideToggle('slow');
      });
    </script>
EOF
end

post '/new_project' do
  project = Project.clone(params[:name],params[:git_uri])
  project.process_features
end

get '/project/:guid' do |guid|
  use_layout = params[:no_template] ? false : true
  erb Project.first(:guid => guid).to_html, :layout => use_layout
end

get '/project/:guid/feature/:feature' do |guid,feature|
  Project.first(:guid => guid).feature(feature)
end

post '/project/:guid/feature/:feature' do |guid,feature_name|
  Project.first(:guid => guid).feature(feature_name).update(params[:text])
  redirect "/project/#{guid}/features"
end

get '/project/:guid/feature/:feature/result' do |guid,feature_name|
  Project.first(:guid => guid).feature(feature_name).result
end

get '/project/:guid/features' do |guid|
  project = Project.first(:guid => guid)
  foo = project.features.inject("") do |result,feature_name|
    feature = project.feature(feature_name)
    result += <<EOF
      <form method='post' action='/project/#{guid}/feature/#{feature.name}'>
        <label for='#{feature.name}'>#{feature.name.humanize}</label><br/>
        <textarea name='text' id='#{feature.name}' class='feature' style='height:200px;width:700px;' >#{feature.to_s}</textarea>
        <input type='submit' value='Save'/>
      </form>
      <div id='#{feature.name}_result'/>
      <script>
        $('##{feature.name}_result').load("/project/#{guid}/feature/#{feature.name}/result")
      </script>
EOF
  end
  erb foo
end

get '/project/:guid/delete' do |guid|
  Project.first(:guid => guid).destroy
end

# This is fairly dangerous because you could send project/234/destroy
# It's also pretty freaking awesome
get '/project/:guid/:attribute' do |guid,attribute|
  Project.first(:guid => guid).send(attribute)
end
