require 'sinatra/base'

class SpecServer < Sinatra::Base
  get '/' do
    'Hello SpecServer!'
  end
end
