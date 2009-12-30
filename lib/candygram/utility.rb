require 'socket'

module Candygram
  module Utility
    
    # Returns the IP address of this machine relative to the MongoDB server
    # From: http://coderrr.wordpress.com/2008/05/28/get-your-local-ip-address/
    def self.local_ip
      orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

      UDPSocket.open do |s|
        s.connect Candygram.connection.host, 1
        s.addr.last
      end
    ensure
      Socket.do_not_reverse_lookup = orig
    end
    
    # Parses Mongo's somewhat inscrutable results from Collection.update when :safe => true
    # and returns whether or not the value was updated.  The basic output looks like this:
    # [[{"err"=>nil, "updatedExisting"=>false, "n"=>0, "ok"=>1.0}], 1, 0]
    def self.update_succeeded?(result)
      result[0][0]["updatedExisting"]
    end
  end
end
    