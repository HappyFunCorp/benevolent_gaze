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
    
    register Sinatra::CrossOrigin
    
    configure do
      if ENV["REDISTOGO_URL"]
        uri = URI.parse(ENV["REDISTOGO_URL"])
        REDIS = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
      else
        REDIS = Redis.new
      end
    end

    get "/" do
      r = REDIS
      if r.get("localhost")
        redirect to(("http://#{r.get("localhost").strip + ':4567/register'}"))
      else
        redirect to("http://happyfuncorp.com")
      end
    end

    post "/" do
      r = REDIS
      puts params[:ip].to_s + "THIS IS THE IP RECEIVED BY THE SERVER FROM BENEVOLENT GAZE"
      r.set("localhost", params[:ip])
    end
  end
end
