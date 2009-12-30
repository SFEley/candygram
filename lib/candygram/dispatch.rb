require 'candygram/connection'
require 'candygram/wrapper'
require 'candygram/utility'

module Candygram
  # Pays attention to the Candygram work queue and forks runners to do the work as needed.
  class Dispatch
    
    # A unique identifier for this dispatcher. Includes local IP address and PID.
    DISPATCH_ID = Utility.local_ip + '/' + Process.pid.to_s
    
    attr_accessor :frequency
    
    # Returns a Dispatch object that will keep checking the Candygram work queue and forking runners.
    # @option options [Integer] :frequency How often to check the queue (in seconds). Defaults to 5.
    def initialize(options={})
      @frequency = options.delete(:frequency) || 5
    end  
    
    # Loops over the work queue.  You can stop it any time with the #finish method if running in a 
    # separate thread. 
    def run
      until @finish
        deliveries = check_queue
        deliveries.each do |del|
          if lock_delivery(del)
            # Runner stuff happens here
          end
        end if deliveries
        sleep frequency
      end
    end
    
    # Tells the #run method to stop running. It's a simple loop condition, not preemptive, so if the 
    # dispatcher is sleeping you may have to wait up to _frequency_ seconds before it really ends.
    def finish
      @finish = true
    end
    
  protected
    # Looks for new work to do
    def check_queue
      # The interesting options hash for our new work query
      check = {
        :deliver_at => {'$lte' => Time.now.utc}
      }
      Candygram.queue.find(check)
    end
    
    # Sets the 'locked' value of the job to prevent anyone else from taking it.
    # Returns true on success, false on failure.
    def lock_delivery(del)
      r = Candygram.queue.update({'_id' => del['_id'], 'locked' => {'$exists' => false}}, # query
                                 {'$set' => {'locked' => DISPATCH_ID}},  # update
                                 :safe => true)
      Utility.update_succeeded?(r)
    rescue Mongo::OperationFailure
      false
    end  
    
  end  
end