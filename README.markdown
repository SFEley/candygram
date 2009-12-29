= Candygram

__"Candygram for Mongo!"__ — _Blazing Saddles_

Candygram is a job queueing system for the MongoDB database.  It is loosely based on the **delayed_job** gem for ActiveRecord and the **Resque** gem for Redis, with the following interesting distinctions:

* Delayed running is explicitly enabled with `include Candygram::Delivery` instead of extending Object.
* Objects with the Delivery module included get magic _*\_later_, _*\_in_, and _*\_at_ variants on every instance method to enqueue the method call for running as soon as possible or at a given time.
* Object states and method arguments are serialized as BSON to take best advantage of Mongo's efficiency.
* Workers can adaptively spawn more workers or die off as the job queue becomes backlogged or empties.  (TODO)
* The job queue is a capped collection; because jobs are never deleted, recent history can be analyzed and failure states reported.


== Copyright

Copyright (c) 2009 Stephen Eley. See LICENSE for details.
