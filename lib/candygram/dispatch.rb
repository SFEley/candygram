require 'candygram/connection'
require 'candygram/wrapper'
require 'candygram/utility'

module Candygram
  # Pays attention to the Candygram work queue and forks runners to do the work as needed.
  class Dispatch
    include Utility
    
    attr_accessor :frequency
    
    # Returns a Dispatch object that will keep checking the Candygram work queue and forking runners.
    # @option options [Integer] :frequency How often to check the queue (in seconds). Defaults to 5.
    def initialize(options={})
      @frequency = options.delete(:frequency) || 5
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
          if lock_delivery(del)
            # Close our connection so that we don't get too many weird copies
            Candygram.connection = nil
            if child = fork
              # We're the parent
              puts "Starting: #{child}"
              add_runner del["class"], child
            else
              # We're the runner
              set_status(del, 'running')
              package = Wrapper.unwrap(del["package"])
              args = Wrapper.unwrap(del["arguments"])
              result = package.send(del["method"].to_sym, *args)
              finish_delivery(del, result)
              Candygram.connection = nil
              exit
            end
          end
        end
        sleep frequency
      end
      finishes = Process.waitall
      finishes.each do |f|
        remove_runner(f[0])
      end
    end
    
    # Tells the #run method to stop running. It's a simple loop condition, not preemptive, so if the 
    # dispatcher is sleeping you may have to wait up to _frequency_ seconds before it really ends.
    def finish
      @finish = true
    end
    
    # Thread-safe accessor for the 'runners' hash.  Honestly, we're mostly keeping this threadsafe
    # for testing, but someone might go nuts and want to use this whole dispatch system in a thread
    # someday.
    def runners
      runner_mutex.synchronize do
        @runners ||= {}
      end
    end
    
    # Pushes a new PID onto the 'runners' hash.
    def add_runner(klass, pid)
      runner_mutex.synchronize do
        (@runners[klass] ||= []).push(pid)
        @index[pid] = klass
      end
    end
    
    # Takes a PID off of the 'runners' hash.
    def remove_runner(pid)
      "Finished: #{pid}"
      runner_mutex.synchronize do
        klass = @index.delete(pid)
        @runners[klass].delete(pid)
      end
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
  
  private
    # A unique identifier for this dispatcher. Includes local IP address and PID.
    def dispatch_id
      local_ip + '/' + Process.pid.to_s
    end
    
    def runner_mutex
      @runner_mutex ||= Mutex.new
    end
  end  
end