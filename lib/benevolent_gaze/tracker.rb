require 'resolv'
require 'httparty'

module BenevolentGaze
  class Tracker
    def self.run!
      # Run forever
      while true
        scan
        check_time
        sleep 10
      end
    end
  end
end