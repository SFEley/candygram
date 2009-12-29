module Candygram
  
  # The MongoDB connection object. Creates a default connection to localhost if not explicitly told otherwise.
  def self.connection
    @connection ||= Mongo::Connection.new
  end
  
  # Accepts a new MongoDB connection, closing any current ones
  def self.connection=(val)
    @connection.close if @connection
    @connection = val
  end
  
  # The Mongo database object.  If you just want the name, use #database instead.
  def self.db
    @db ||= Mongo::DB.new(DEFAULT_DATABASE, connection)
  end
  
  # Sets the Mongo database object. Unless you want to pass specific options or bypass the 
  # Candygram connection object completely, it's probably easier to use the #database= method 
  # and give it the name.
  def self.db=(val)
    @db = val
  end
  
  # The name of the Mongo database object.
  def self.database
    db.name
  end
  
  # Creates a Mongo database object with the given name and default options.
  def self.database=(val)
    self.db = Mongo::DB.new(val, connection)
  end
  
  # The delivery queue collection. If not set, creates a capped collection with a default
  # name of 'candygram_queue' and a default cap size of 100MB.
  def self.queue
    @queue or begin
      if db.collection_names.include?(DEFAULT_QUEUE)
        @queue = db[DEFAULT_QUEUE]
      else
        @queue = create_queue
      end
    end
  end
  
  # Sets the delivery queue to an existing collection.  Assumes you know what you're doing 
  # and have made all the proper indexes and such.  If not, use the #create_queue method instead.
  def self.queue=(val)
    @queue = val
  end
  
  # Creates a new capped collection with the given name and cap size, and sets the indexes needed
  # for efficient Candygram delivery.
  def self.create_queue(name=DEFAULT_QUEUE, size=DEFAULT_QUEUE_SIZE)
    q = db.create_collection(name, :capped => true, :size => size)
    # Make indexes here...
  end
end