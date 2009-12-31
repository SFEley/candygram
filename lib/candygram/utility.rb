require 'socket'

module Candygram
  
  # Various methods that may be useful to both delivery and dispatch.
  module Utility
    
    # Returns the IP address of this machine relative to the MongoDB server.
    # From: http://coderrr.wordpress.com/2008/05/28/get-your-local-ip-address/
    def local_ip
      @local_ip or begin
        orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

        @local_ip = UDPSocket.open do |s|
          s.connect Candygram.connection.host, 1
          s.addr.last
        end
      ensure
        Socket.do_not_reverse_lookup = orig
      end
    end
    
    # Parses Mongo's somewhat inscrutable results from Collection.update when :safe => true
    # and returns whether or not the value was updated.  The basic output looks like this:
    # [[{"err"=>nil, "updatedExisting"=>false, "n"=>0, "ok"=>1.0}], 1, 0]
    def update_succeeded?(result)
      result[0][0]["updatedExisting"]
    end
    
    # Pushes a new status message onto the job.  Includes an identifier for this process and a timestamp.
    def set_status(del, state)
      Candygram.queue.update({'_id' => del['_id']}, {'$push' => {'status' => status_hash(state)}})
    end
    
  protected
    # Returns an embedded document suitable for pushing onto a delivery's status array.
    def status_hash(state)
      message = {
        'ip' => local_ip,
        'pid' => Process.pid,
        'state' => state,
        'at' => Time.now.utc
      }
    end
  end
end
    