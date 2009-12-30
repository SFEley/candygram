require 'candygram/connection'
require 'candygram/wrapper'

module Candygram
  # The special sauce that allows an object to place its method calls into the job queue. 
  module Delivery
    
    # Lazily adds magic Candygram delivery methods to the class.
    def method_missing(name, *args)
      if name =~ /(\S+)_later$/
        self.class.class_eval <<-LATER
          def #{name}(*args)
            send_candygram("#{$1}", *args)
          end
          LATER
        send(name, *args)
      else
        super
      end
    end
    
  protected
    # Does the tricky work of adding the method call to the MongoDB queue. Dollars to donuts that
    # this method name doesn't conflict with anything you're already using...
    def send_candygram(method, *args)
      gram = {
        :class => self.class.name,
        :package => Wrapper.wrap_object(self),
        :method => method,
        :arguments => Wrapper.wrap_array(args),
        :created_at => Time.now.utc,
        :deliver_at => Time.now.utc
      }
      Candygram.queue << gram
    end
  end
end