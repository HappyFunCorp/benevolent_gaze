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
      if (@@old_time + (30*60)) <= Time.now.to_i
        #Post local ip HTTParty.post('http://www.happyfuncorp.com/ident', query: {ip: `ipconfig getpacket en0 | yiaddr`.split(" = ")[-1].strip})
        @old_time = Time.now.to_i
        puts "Just sent local ip to server for identification."
      end
    end
    
    def scan
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
      puts device_names_and_ip_addresses
      begin
        HTTParty.post('http://localhost:4567/information', query: {devices: device_names_and_ip_addresses.to_json } )
      rescue
        puts "Looks like you might not have your server up and running"
      end
    end
  end
  end
end
