require 'json'
require 'sinatra/base'
require 'sinatra/support'
require 'sinatra/json'
require 'redis'

Encoding.default_external = 'utf-8'  if defined?(::Encoding)

module BenevolentGaze
  class Kiosk < Sinatra::Base
    set server: 'thin', connections: []
    set :bind, '0.0.0.0'
    set :static, true
    set :public_folder, File.expand_path( "../../../frontend/build", __FILE__ )

    get "/" do
      redirect "index.html"
    end

    get "/feed", provides: 'text/event-stream' do
      stream :keep_open do |out|
        loop do 
          if out.closed?
            break
          end

          data = { "name_update" => false, "changes" => true }
          out << "data: #{data.to_json}\n\n"

          sleep 1
        end
      end
    end
  end
end