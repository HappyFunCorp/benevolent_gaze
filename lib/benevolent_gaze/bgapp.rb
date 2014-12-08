require 'json'
require 'sinatra/base'
require 'sinatra/support'
require 'sinatra/json'
require 'redis'
require 'sinatra/cross_origin'

Encoding.default_external = 'utf-8'  if defined?(::Encoding)

module BenevolentGaze
  class BGApp < Sinatra::Base
    set server: 'thin', connections: []
    set :bind, '0.0.0.0'
    
    register Sinatra::CrossOrigin
    
    get "/" do
      r = Redis.new
      if r.get("localhost")
        redirect to(("http://#{r.get("localhost").strip + ':4567/register'}"))
      else
        redirect to("http://happyfuncorp.com")
      end
    end

    post "/" do
      r = Redis.new
      r.set("localhost", params[:ip])
    end
  end
end
