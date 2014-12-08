require 'json'
require 'sinatra/base'
require 'sinatra/support'
require 'sinatra/json'
require 'redis'
require 'resolv'
require 'sinatra/cross_origin'
require 'aws/s3'
require 'SecureRandom'
require 'mini_magick'

Encoding.default_external = 'utf-8'  if defined?(::Encoding)

module BenevolentGaze
  class Kiosk < Sinatra::Base
    set server: 'thin', connections: []
    set :bind, '0.0.0.0'
    set :app_file, __FILE__
    set :port, ENV['PORT']
    set :static, true
    set :public_folder, File.expand_path( "../../../frontend/build", __FILE__ )
    
    register Sinatra::CrossOrigin

    helpers do
      def upload(filename, file, device_name)
        doomsday = Time.mktime(2038, 1, 18).to_i
        if (filename)
          new_file_name = device_name.to_s + SecureRandom.uuid.to_s + filename.gsub(".jpg", ".png")
          bucket = ENV['AWS_CDN_BUCKET']
          image = MiniMagick::Image.open(file.path)
          image.auto_orient
          if image.height > image.width
            image.resize "300"
            offset = (image.width/2) - 150
            image.crop("300x300+0+#{offset}")
          else
            image.resize "x300"
            offset = (image.height/2) - 150
            image.crop("300x300+#{offset}+0")
          end
          image.format "png"

          AWS::S3::Base.establish_connection!(
            :access_key_id     => ENV['AWS_ACCESS_KEY_ID'],
            :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
          )
          AWS::S3::S3Object.store(
            new_file_name,
            image.to_blob,
            bucket,
            :access => :public_read
          )
          image_url = AWS::S3::S3Object.url_for( new_file_name, bucket, :expires => doomsday )
          return image_url 
        else
          return nil
        end
      end
    end

    get "/" do
      redirect "index.html"
    end
    
    post "/register" do
      dns = Resolv.new
      device_name = dns.getname(request.ip)
      r = Redis.new
      devices = JSON.parse(r.get("all_devices"))
      if params[:real_first_name] || params[:real_last_name]
        compound_name = "#{params[:real_first_name].to_s}  #{params[:real_last_name].to_s}"
      end
      devices[device_name] = compound_name.empty? ? device_name : compound_name
      r.set("all_devices", devices.to_json)
      puts params[:real_name].to_s + " just added their real name."
      puts params
      if params[:fileToUpload]
        image_url_returned_from_upload_function = upload(params[:fileToUpload][:filename], params[:fileToUpload][:tempfile], device_name)
        devices_with_images = r.get("devices_images") || "{}" 
        parsed_devices_with_images = JSON.parse(devices_with_images)
        parsed_devices_with_images[device_name] = image_url_returned_from_upload_function
        r.set("devices_images", parsed_devices_with_images.to_json)
      end
      puts r.get("all_devices")
      puts r.get("devices_images")
      puts r.get("devices_on_network")
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
          data = JSON.parse(r.get("devices_on_network") || "{}").map do |k,v|
            { device_name: k, name: v, last_seen: Time.now.to_f * 1000, avatar: JSON.parse(r.get("devices_images") || "{}" )[k] } 
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
