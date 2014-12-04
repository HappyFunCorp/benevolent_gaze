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
    set :static, true
    set :public_folder, File.expand_path( "../../../website/build", __FILE__ )
    
    register Sinatra::CrossOrigin
    
    get "/register" do
      r = Redis.new
      if r.get("localhost")
        redirect "#{r.get("localhost") + '/register'}"
      else
        redirect "index.html"      
      end
    end

    post "/ident" do
      r = Redis.new
      r.set("localhost", params[:localhost])
    end

    get "/benevolent_gaze" do
      redirect "index.html"
    end
  end
end
