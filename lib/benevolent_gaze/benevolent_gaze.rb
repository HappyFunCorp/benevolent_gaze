require 'thor'
require 'csv'
include FileUtils

module BenevolentGaze
  class Cli < Thor
    desc "add_user device name image", "Add single user's device name, name and image"
    long_desc <<-LONGDESC
      This command takes a user's device name, real name and image url and maps them
      so that Benevolent Gaze can use the information when they log onto your network.
    LONGDESC
    
    def add_user(device_name, name, image_url)
      `redis-cli set "name:#{device_name}" "#{name}"`
      `redis-cli set "image:#{device_name}" "#{image_url}"`
    end
    
    desc "assign_users", "This will prompt you for each current user without an associated name so that you can assign one."    
    def assign_users
      users = `redis-cli hgetall "current_devices"`.split("\n")
      
      users.each do |u|
        val = `redis-cli hget "current_devices" "#{u}"`
        if val.strip.empty? && !u.empty?
          puts "Do you know whose device this is #{u}? ( y/n )"
          response = $stdin.gets.chomp.strip
          if response == "y"
            puts "Please enter their name."
            name_response = $stdin.gets.chomp.strip
            `redis-cli set "name:#{u}" "#{name_response}"`

            puts "Do you have an image for this user? ( y/n )"
            image_response = $stdin.gets.chomp.strip
            if image_response == "y"
              puts "Please enter the image url."
              image_url_response = $stdin.gets.chomp.strip
              `redis-cli set "image:#{u}" "#{image_url_response}"`
            end 
          end
        else
          puts "#{Thor::Shell::Color::MAGENTA}It looks like this user has a name already  associated with them.#{Thor::Shell::Color::CLEAR}"
        end
      end
      self.bg_flair
    end

    desc "bulk_assign yourcsv.csv", "This takes a csv file as an argument formated in the following way. device_name, real_name, image_url"
    def bulk_assign(csv_path)
      CSV.foreach(csv_path) do |row|
        device_name = row[0]
        real_name = row[1]
        image_url = row[2]

        unless real_name.empty?
          `redis-cli set "name:#{device_name}" "#{real_name}"`
        end

        unless image_url.empty?
          `redis-cli set "image:#{device_name}" "#{image_url}"`
        end
      end
      puts `redis-cli keys "*"`
      puts "#{Thor::Shell::Color::MAGENTA}The CSV has now been added.#{Thor::Shell::Color::CLEAR}"
      self.bg_flair
    end

    desc "generate generates a Procfile and .env file", "This command generates a Procfile and .env file for you to use with Benevolent Gaze."
    def generate
      cp("#{File.dirname(__FILE__)}/../../bin/Procfile", "./Procfile")
      cp("#{File.dirname(__FILE__)}/../../bin/.user_env", "./.env")
      puts "Copied Procfile and .env file to current directory"
      self.bg_flair
    end

    desc "generate_and_customize generates Procfile and .env file and copy frontend components to current directory.", "This command generates the Procfile, .env file and copies the front end components directory into the current directory so you can customize the look."
    def generate_and_customize
      self.generate
      cp_r("#{File.dirname(__FILE__)}/../../frontend", "./frontend")
      contents = File.read("#{File.dirname(__FILE__)}/../../lib/benevolent_gaze/kiosk.rb")
      new_path = File.expand_path("./frontend/build")
      contents.gsub!(/.*public_folder.*/, "\t\tset :public_folder, \"#{new_path}\"") 
      
      File.open("#{File.dirname(__FILE__)}/../../lib/benevolent_gaze/kiosk.rb", "w") do |f|
        f << contents
      end

      puts <<-CUSTOMIZE

      #{Thor::Shell::Color::MAGENTA}**************************************************#{Thor::Shell::Color::CLEAR}

      Generated Procfile and .env and copied frontend folder into current directory.
      
      You can now customize your kiosk, by switching out the graphics in frontend/source/images.
      Please replace the images with the images of the same size.
      Then you will need to run:

      #{Thor::Shell::Color::MAGENTA}$ bundle exec middleman build#{Thor::Shell::Color::CLEAR}

      This rebuilds your project. Then you can restart Benevolent Gaze And VOILA! You have your new kiosk!

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
