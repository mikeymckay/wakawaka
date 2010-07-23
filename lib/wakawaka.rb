require 'rubygems'
require 'sinatra'
#require 'sinatra/base'

class Wakawaka < Sinatra::Base
  set :public, 'public'
  get '/' do
    erb :home
  end
end
