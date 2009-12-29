require 'date'  # Only so we know what one is. Argh.

module Candygram
  # Utility methods to serialize and unserialize objects into BSON
  module Wrapper
    
    BSON_SAFE = [String, 
                NilClass, 
                TrueClass, 
                FalseClass, 
                Fixnum, 
                Float, 
                Time,
                ByteBuffer, 
                Mongo::ObjectID, 
                Mongo::Code,
                Mongo::DBRef]
    
    # Makes an object safe for the sharp pointy edges of MongoDB. Types properly serialized
    # by the BSON.serialize call get passed through unmolested; others are unpacked and their
    # pieces individually shrink-wrapped.
    def self.wrap(thing)
      # Pass the simple cases through
      return thing if BSON_SAFE.include?(thing.class)
      case thing
      when Date
        thing.to_time
        
      end
    end
    
    # Takes an array and returns the same array with unsafe objects wrapped
    def self.wrap_array(array)
      array.map {|element| wrap(element)}
    end
    
    
  end
end 
  