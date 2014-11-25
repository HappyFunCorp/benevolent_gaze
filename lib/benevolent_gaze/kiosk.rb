require 'json'
require 'sinatra/base'
require 'sinatra/support'
require 'sinatra/json'
require 'redis'
require 'resolv'
require 'sinatra/cross_origin'

Encoding.default_external = 'utf-8'  if defined?(::Encoding)

module BenevolentGaze
  class Kiosk < Sinatra::Base
    set server: 'thin', connections: []
    set :bind, '0.0.0.0'
    set :static, true
    set :public_folder, File.expand_path( "../../../frontend/build", __FILE__ )
    
    register Sinatra::CrossOrigin

    get "/" do
      redirect "index.html"
    end
    
    post "/register" do
      dns = Resolv.new
      device_name = dns.getname(request.ip)
      r = Redis.new
      devices = JSON.parse(r.get("all_devices"))
      devices[device_name] = params[:real_name]
      r.set("all_devices", devices.to_json)
      puts params[:real_name].to_s + " just added their real name."
      puts r.get("all_devices")
      redirect "thanks.html"
    end

    get "/register" do
      redirect "register.html"
    end

    get "/feed", provides: 'text/event-stream' do
      cross_origin
      r = Redis.new
      
      stream :keep_open do |out|
        loop do 
          if out.closed?
            break
          end
          data = JSON.parse(r.get("devices_on_network")).map do |k,v|
            { device_name: k, name: v, last_seen: Time.now.to_f * 1000 }
          end
          out << "data: #{data.to_json}\n\n"

          sleep 1
        end
      end
    end

    post "/information" do
      #grab current devices on network.  Save them to the devices on network key after we make sure that we grab the names that have been added already to the whole list and then save them to the updated hash for redis.
      devices_on_network = JSON.parse(params[:devices]) 
      r = Redis.new
      all_devices = r.get("all_devices") || "{}"
      parsed_all_devices = JSON.parse(all_devices)
      current_devices = devices_on_network
      current_devices_with_names = {}
      current_devices.map do |k,v|
        unless parsed_all_devices.keys.include?(k)
          parsed_all_devices[k] = v 
        end
        current_devices_with_names[k] = parsed_all_devices[k]
      end
      r.set("devices_on_network",current_devices_with_names.to_json)
      r.set("all_devices", parsed_all_devices.to_json)

    end
  end
end
