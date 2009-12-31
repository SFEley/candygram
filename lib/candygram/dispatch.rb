require 'candygram/connection'
require 'candygram/wrapper'
require 'candygram/utility'

module Candygram
  # Pays attention to the Candygram work queue and forks runners to do the work as needed.
  class Dispatch
    include Utility
    
    attr_accessor :frequency, :quiet, :max_per_class
    attr_reader :runners
    
    # Returns a Dispatch object that will keep checking the Candygram work queue and forking runners.
    # @option options [Integer] :frequency How often to check the queue (in seconds). Defaults to 5.
    def initialize(options={})
      @frequency = options.delete(:frequency) || 5
      @max_per_class = options.delete(:max_per_class) || 10
      @quiet = options.delete(:quiet)
      @runners = {}
      @index = {}
    end  
    
    # Loops over the work queue.  You can stop it any time with the #finish method if running in a 
    # separate thread. 
    def run
      Kernel.trap("CLD") do 
        pid = Process.wait
        remove_runner(pid)
      end
      
      until @finish
        deliveries = check_queue
        deliveries.each do |del|
          if slot_open?(del) && lock_delivery(del)
            puts "Delivering #{del["class"]}\##{del["method"]} at #{Time.now}" unless quiet
            # Close our connection so that we don't get too many weird copies
            Candygram.connection = nil
            child = fork do
              # We're the runner
              set_status(del, 'running')
              package = Wrapper.unwrap(del["package"])
              args = Wrapper.unwrap(del["arguments"])
              result = package.send(del["method"].to_sym, *args)
              finish_delivery(del, result)
              Candygram.connection = nil
              exit
            end
            # We're the parent
            add_runner del["class"], child
            sleep(0.2)  # Give connections time to wrap up
          end
        end
        sleep frequency
      end
      until @index.empty?
        sleep(0.1) # We trust our trap
      end
    end
    
    # Tells the #run method to stop running. It's a simple loop condition, not preemptive, so if the 
    # dispatcher is sleeping you may have to wait up to _frequency_ seconds before it really ends.
    def finish
      @finish = true
    end
    
    # Pushes a new PID onto the 'runners' hash.
    def add_runner(klass, pid)
      @runners[klass] ||= []
      @runners[klass] << pid
      @index[pid] = klass
    end
    
    # Takes a PID off of the 'runners' hash.
    def remove_runner(pid)
      klass = @index.delete(pid)
      @runners[klass].delete(pid)
    end
    
  protected
    # Looks for new work to do
    def check_queue
      # The interesting options hash for our new work query
      check = {
        :deliver_at => {'$lte' => Time.now.utc},
        :result => {'$exists' => false},
        :locked => {'$exists' => false}
      }
      Candygram.queue.find(check).to_a
    end
    
    # Sets the 'locked' value of the job to prevent anyone else from taking it.
    # Returns true on success, false on failure.
    def lock_delivery(del)
      r = Candygram.queue.update({'_id' => del['_id'], 'locked' => {'$exists' => false}}, # query
                                 {'$set' => {'locked' => dispatch_id}},  # update
                                 :safe => true)
      update_succeeded?(r)
    rescue Mongo::OperationFailure
      false
    end

    # Removes the 'locked' value of the job.
    def unlock_delivery(del)
      Candygram.queue.update({'_id' => del['_id']}, {'$set' => {'locked' => nil}})
    end
    
    # Logs the result of the method call to the delivery.  If the result is nil it will be logged
    # as the word "nil".
    def finish_delivery(del, result)
      Candygram.queue.update({'_id' => del['_id']}, {'$set' => {'result' => (result.nil? ? 'nil' : Wrapper.wrap(result))}})
      unlock_delivery(del)
      set_status(del,'completed')
    end
    
    # Checks whether we've hit the maximum number of simultaneous runners for this particular class.
    # Limits are determined by (in order of precedence):
    # 1. The value of a CANDYGRAM_MAX constant set in the class being delivered;
    # 2. The max_per_class attribute of the Dispatch object;
    # 3. The generic default of 10.
    def slot_open?(del)
      klass = Kernel.const_get(del["class"])
      if klass.const_defined?(:CANDYGRAM_MAX)
        limit = klass::CANDYGRAM_MAX
      else
        limit = max_per_class
      end
      (@runners[del["class"]] ? @runners[del["class"]].length < limit : true)
    end
  
  private
    # A unique identifier for this dispatcher. Includes local IP address and PID.
    def dispatch_id
      local_ip + '/' + Process.pid.to_s
    end
  end  
end