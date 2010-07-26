require 'rubygems'
require 'sinatra'
#require 'sinatra/base'

class Wakawaka < Sinatra::Base
  set :public, 'public'

  def data_dir
    settings.environment.to_s + "_data/"
  end

  def projects
    YAML.load_file(data_dir + "projects.yml") rescue nil || {}
  end

  get '/' do
    erb :home
  end

  get '/projects' do
    puts projects.inspect
    return
    projects.map{|project_name| 
      "<li>#{project_name}<small>#{projects[project_name][:git_url]}</small></li>"
    }.join
  end

  post '/new_project' do
    projects[params[:project_name]] = {:git_url => params[:git_url]}
    puts "######"
    puts projects.inspect
    return
    File.open(data_dir + "projects.yml","w+") do |file|
      file.puts projects.to_yaml
    end
  end

end
