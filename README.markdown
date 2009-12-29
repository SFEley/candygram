= Candygram

__"Candygram for Mongo!"__ — _Blazing Saddles_

Candygram is a job queueing system for the MongoDB database.  It is loosely based on the **delayed_job** gem for ActiveRecord and the **Resque** gem for Redis, with the following interesting distinctions:

* Delayed running is explicitly enabled with `include Candygram::Delivery` instead of extending Object.
* Objects with the Delivery module included get magic _*\_later_, _*\_in_, and _*\_at_ variants on every instance method to enqueue the method call for running as soon as possible or at a given time.
* Object states and method arguments are serialized as BSON to take best advantage of Mongo's efficiency.
* Workers can adaptively spawn more workers or die off as the job queue becomes backlogged or empties.  (TODO)
* The job queue is a capped collection; because jobs are never deleted, recent history can be analyzed and failure states reported.

== Limitations

The serialization employed here is vaguely similar to that employed to YAML.to_yaml, but simpler. You can pass most objects as parameters, but the following will not work:

* You cannot pass blocks or procs to delayed methods.  There's just no robust way to capture and serialize the things.
* Objects with singleton methods or module extensions outside their class will lose them.
* Object classes must accept the `.new` method without any parameters.  Any initialization magic that depends on arguments passed in will be confused.
* In general, objects that maintain state in any way cleverer than their instance variables will get unclever, and probably unpredictable.
* Circular object graphs will probably cause explosions.



== Copyright

Copyright (c) 2009 Stephen Eley. See LICENSE for details.
