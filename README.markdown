# Candygram

__"Candygram for Mongo!"__ — _Blazing Saddles_

Candygram is a job queueing system for the MongoDB database.  It is loosely based on the **delayed_job** gem for ActiveRecord and the **Resque** gem for Redis, with the following interesting distinctions:

* Delayed running can be added to any class with `include Candygram::Delivery`.
* Objects with the Delivery module included get magic _*\_later_ variants on every instance method to enqueue the method call.  (_*\_in_ and _*\_at_ variants coming soon to specify a time of execution.)
* Object states and method arguments are serialized as BSON to take best advantage of Mongo's efficiency.
* A centralized dispatcher forks runners to handle each job, with maximum limits defined per class.
* The job queue is a capped collection; because jobs are never deleted, recent history can be analyzed and failure states reported.

## Installation

Come on, you've done this before:

    $ sudo gem install candygram
    
Candygram requires the **mongo** gem, and you'll probably be much happier if you install the **mongo\_ext** gem as well. The author uses only Ruby 1.9, but it _should_ work in Ruby 1.8.  If it doesn't, please report a bug in Github's issue tracking system.

## Configuration

Both the Delivery and the Dispatcher modules take some configuration
parameters to connect to the proper Mongo collection:
    
    # Makes a default connection to 'localhost' if you don't override it
    Candygram.connection = Mongo::Connection.new(_params_)  
    
    # Creates a default 'candygram' database if you don't override it
    Candygram.database = 'my_database'
    
    # Creates a default 'candygram_queue' collection if you don't -- you get the picture.
    Candygram.queue = Candygram.database.collection('my_queue')
    # Or, to make a brand new queue with the proper indexes:
    Candygram.create_queue('my_queue', 1048576) # 1MB capped collection
    
## Creating Jobs

You can set up any Ruby class to delay method executions by including the Delivery module: 
  
    require 'candygram'
    
    class Explosive
      include Candygram::Delivery  
      CANDYGRAM_MAX = 5  # Optional; limits simultaneous runners per dispatcher

      def kaboom(planet)
        "A #{planet}-shattering kaboom!"
      end
    end

You can continue to use the class as you normally would, of course.  If you want to queue a method to run later, just add _\_later_ to the method name:

    e = Explosive.new
    e.kaboom_later('Mars')

This will serialize the object _e_ (including any instance variables) into a Mongo document, along with the method name and the argument.  The Candygram dispatcher will find it the next time it looks for jobs to run.  It will fork a separate process to unpack the object, call the `kaboom` method, and save the return value in the job document for later reference.

## Dispatching

Nice Rake tasks and Rails generators and such are still pending.  In the meantime, you can easily make your own dispatch script and call it with Rake or cron or trained beagle or what-have-you:

    require 'candygram'
    require 'my_environment'  # Whatever else you need to make your classes visible
    
    # Config parameters can be passed as a hash to `new` or by setting attributes.
    d = Candygram::Dispatch.new  
    d.frequency = 10     # Check for jobs every 10 seconds (default 5)
    d.max_per_class = 20 # Simultaneous runners per class (default 10)
    d.quiet = true       # Don't announce work on standard output (default false)
    
    # This is the central method that loops and checks for work...
    d.run
    
    # You can kill the loop with CTRL-C or a 'kill' of course, or by
    # calling 'd.finish' (but to make that work, you'd need to access 
    # it from a separate thread).

The dispatcher forks a separate process for each job in the queue, constrained by the per-class limits set by the CANDYGRAM_MAX constant in the class or by the **max\_per\_class** configuration variable.  It keeps track of its child PIDs and will wait for them to finish if shut down gracefully.  Jobs are locked so that dispatchers on multiple servers can be run against the same queue.

Job runners push status information onto the document to indicate time of running and completion.  Future enhancements will likely include some reporting on this data, detection and rerunning on exception or timeout, and (possibly) optimization based on average run times.
  
## Limitations

* You cannot pass blocks or procs to delayed methods.  There's just no robust way to capture and serialize the things.
* Objects with singleton methods or module extensions outside their class will lose them.
* Object classes must accept the `.new` method without any parameters.  It's probably a good idea not to pass objects that have complex initialization.
* In general, objects that maintain state in any way cleverer than their instance variables will become stupid and probably unpredictable.
* Circular object graphs will probably cause explosions.
* Because it uses `fork`, this won't run on Windows.  (A limitation which bothers me not one iota.)

## Big Important Disclaimer

This is still very very alpha software.  I needed this for a couple of my own projects, but I'm pushing it into the wild _before_ proving it on those projects; if I don't, I'll probably lose energy and forget to do all the gem bundling and such.  It's not nearly as robust yet as I hope to make it: there's a lot more I want to do for handling error cases and making the dispatcher easy to keep running.

I welcome your suggestions and bug reports using the Github issue tracker.  I'm happy to take pull requests as well.  If you use this for any interesting projects, please drop me a line and let me know about it -- eventually I may compile a list.

Have Fun.


## Copyright

Copyright (c) 2009 Stephen Eley. See LICENSE for details.
