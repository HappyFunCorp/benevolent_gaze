require 'thor'
require 'thor/actions'
require 'csv'
require 'benevolent_gaze/kiosk'
require 'benevolent_gaze/tracker'

include FileUtils

module BenevolentGaze
  class Cli < Thor
    include Thor::Actions
    source_root File.expand_path("../../../kiosk", __FILE__)
   
    desc "kiosk", "Start up the sinatra app that displays the users"
    def kiosk
      BenevolentGaze::Kiosk.run!
    end

    desc "tracker", "Start up the tracking daemon that looks at the network"
    def tracker
      BenevolentGaze::Tracker.run!
    end

    desc "add_user device name image", "Add single user's device name, name and image"
    long_desc <<-LONGDESC
      This command takes a user's device name, real name and image url and maps them
      so that Benevolent Gaze can use the information when they log onto your network.
    LONGDESC
    
    def add_user(device_name, name, image_url)
      `redis-cli set "name:#{device_name}" "#{name}"`
      `redis-cli set "image:#{name}" "#{image_url}"`
    end
    
    desc "assign_users", "This will prompt you for each current user without an associated name so that you can assign one."    
    def assign_users
      # users = `redis-cli hgetall "current_devices"`.split("\n")
      require 'redis'
      redis = Redis.new
      users = redis.hgetall "current_devices"

      puts "Right now, these are the devices on your network"
      users.each { |u,v| puts "  #{u}" }
      
      users.each do |u, val|
        val = redis.get "name:#{u}"
        if val.nil? || val.empty?
          puts "Do you know whose device this is #{u}? ( y/n )"
          response = $stdin.gets.chomp.strip
          if response == "y"
            puts "Please enter their name."
            name_response = $stdin.gets.chomp.strip
            redis.set "name:#{u}", "#{name_response}"
            # `redis-cli set "name:#{u}" "#{name_response}"`

            puts "Do you have an image for this user? ( y/n )"
            image_response = $stdin.gets.chomp.strip
            if image_response == "y"
              puts "Please enter the image url."
              image_url_response = $stdin.gets.chomp.strip
              redis.set "image:#{name_response}", image_url_response
            end 
          end
        else
          puts "#{Thor::Shell::Color::MAGENTA}#{u} looks like it has a name already associated with them.#{Thor::Shell::Color::CLEAR}"
        end
      end
      self.bg_flair
    end

    desc "dump_csv [FILENAME]", "This dumps the current_devices"
    def dump_csv( filename )
      require 'redis'
      redis = Redis.new
      users = redis.hgetall "current_devices"
      CSV.open( filename, "wb" ) do |out|
        users.each do |device, name|
          name = redis.get "name:#{device}"
          image = redis.get "image:#{name}"
          out << [device,name,image]
        end
      end
      self.bg_flair
      puts "#{filename} created"
    end

    desc "bulk_assign yourcsv.csv", "This takes a csv file as an argument formated in the following way. device_name, real_name, image_url"
    def bulk_assign(csv_path)
      CSV.foreach(csv_path) do |row|
        puts "Loading device info for #{row[0]} -> #{row[1]}"
        device_name = row[0]
        real_name = row[1]
        image_url = row[2]

        unless real_name.nil? || real_name.empty?
          `redis-cli set "name:#{device_name}" "#{real_name}"`
        end

        unless image_url.nil? || image_url.empty? 
          `redis-cli set "image:#{real_name}" "#{image_url}"`
        end
      end
      # puts `redis-cli keys "*"`
      puts "#{Thor::Shell::Color::MAGENTA}The CSV has now been added.#{Thor::Shell::Color::CLEAR}"
      self.bg_flair
    end

    desc "install wifi_username, wifi_password", "This commands installs the necessary components in the gem and pulls the assets into a local folder so that you can save to your local file system if you do not want to use s3 and also enables you to customize your kiosk."
    def install(uname, pass)
      directory ".", "bg_public"
      env_file = "bg_public/.env"
      new_path = File.expand_path("./bg_public")
      gsub_file(env_file, /.*PUBLIC_FOLDER.*/, "PUBLIC_FOLDER=\"#{new_path}/public\"") 
      gsub_file("bg_public/public/index.html", "happyfuncorp3", uname)
      gsub_file("bg_public/public/index.html", "happiness4u", pass) 
      puts <<-CUSTOMIZE

      #{Thor::Shell::Color::MAGENTA}**************************************************#{Thor::Shell::Color::CLEAR}

      Generated the bg_public folder where you should go to customize images and to run 

      ```foreman start```

      Please modify the .env file with the relevant information mentioned in the README.

      You can now customize your kiosk, by switching out the graphics in the images folder.
      Please replace the images with the images of the same size.

      Uploaded images will save to your local filesystem if you do not supply AWS creds.

      #{Thor::Shell::Color::MAGENTA}**************************************************#{Thor::Shell::Color::CLEAR}
      CUSTOMIZE

      self.bg_flair
    end

    desc "bg_flair prints Benevolent Gaze in ascii art letters, because awesome.", "This command prints Benevolent Gaze in ascii art letters, because...um...well...it's cool looking!"
    def bg_flair
      @bg = <<-BG
        #{Thor::Shell::Color::CYAN}
    ____                             _            _      _____               
   |  _ \\                           | |          | |    / ____|               
   | |_) | ___ _ __   _____   _____ | | ___ _ __ | |_  | |  __  __ _ _______ 
   |  _ < / _ \\ '_ \\ / _ \\ \\ / / _ \\| |/ _ \\ '_ \\| __| | | |_ |/ _` |_  / _ \\
   | |_) |  __/ | | |  __/\\ V / (_) | |  __/ | | | |_  | |__| | (_| |/ /  __/
   |____/ \\___|_| |_|\\___| \\_/ \\___/|_|\\___|_| |_|\\__|  \\_____|\\__,_/___\\___|

        #{Thor::Shell::Color::CLEAR}
      BG
      puts @bg
    end
  end
end
