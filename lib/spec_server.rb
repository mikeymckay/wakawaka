require 'rubygems'
require 'sinatra'
#require 'sinatra/base'

class SpecServer < Sinatra::Base
  get '/' do
    erb :home
  end
end
