require 'resolv'
require 'httparty'

module BenevolentGaze
  class Tracker
    @@old_time = Time.now.to_i

    def self.run!
      # Run forever
      while true
        scan
        check_time
        sleep 10
      end
    end

  class << self
    private
    
    def check_time
      #if ((@@old_time + (30*60)) <= Time.now.to_i)
      if (@@old_time <= Time.now.to_i)
        begin
          #TODO make sure to change the url to read from an environment variable for the correct company url.
        HTTParty.post( (ENV['BG_COMPANY_URL'] || 'http://localhost:3000/register'), query: { ip: `ifconfig | awk '/inet/ {print $2}' | grep -E '[[:digit:]]{1,3}\.' | tail -1` })
        puts "Just sent localhost ip to server."
        rescue
          puts "Looks like there is something wrong with the endpoint to identify the localhost."
        end
        @old_time = Time.now.to_i
      end
    end
    
    def scan
=begin
      # Look for the network broadcast address
      broadcast = `ifconfig -a | grep broadcast`.split[-1]

      # puts "Broadcast Address #{broadcast}"
      unless broadcast =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
        puts "#{broadcast} doesn't look correct"
        exit 1
      end

      # Ping the broadcast address 4 times and wait for responses
      ips = `ping -t 4 #{broadcast}`.split(/\n/).collect do |x|
        if x =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):/
          $1
        else
          nil
        end
      end.select { |x| x && x != broadcast}.sort.uniq

      dns = Resolv.new
      device_names_and_ip_addresses = {}
      
      ips.each do |ip|
        name = dns.getname ip
        device_names_and_ip_addresses[name] = nil
      end
      puts "****************************"
=end
      device_names_hash = {}
      device_names_arr = `for i in {1..254}; do echo ping -t 4 192.168.1.${i} ; done | parallel -j 0 --no-notice 2> /dev/null | awk '/ttl/ { print $4 }' | sort | uniq | sed 's/://' | xargs -n 1 host | awk '{ print $5 }' | sed 's/\.$//'`.split(/\n/)
      device_names_arr.each do |d|
        unless d.match(/Wireless|EPSON/)
          device_names_hash[d] = nil
        end
      end
      puts device_names_hash
      begin
        HTTParty.post('http://localhost:4567/information', query: {devices: device_names_hash.to_json } )
      rescue
        puts "Looks like you might not have the Benevolent Gaze gem running"
      end
    end
  end
  end
end
