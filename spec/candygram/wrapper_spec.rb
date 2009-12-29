require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Candygram
  describe Candygram::Wrapper do
    before(:each) do
      @this = Missile.new
    end
  
    it "can wrap an array of simple arguments" do
      a = ["Hi", 1, nil, 17.536]
      Wrapper.wrap_array(a).should == a
    end
    
    it "can wrap a string" do
      Wrapper.wrap("Hi").should == "Hi"
    end

    it "can wrap nil" do
      Wrapper.wrap(nil).should == nil
    end
    
    it "can wrap true" do
      Wrapper.wrap(true).should be_true
    end
    
    it "can wrap false" do
      Wrapper.wrap(false).should be_false
    end
    
    it "can wrap an integer" do
      Wrapper.wrap(5).should == 5
    end
    
    it "can wrap a float" do
      Wrapper.wrap(17.950).should == 17.950
    end
    
    it "can wrap an already serialized bytestream" do
      b = BSON.serialize(:foo => 'bar')
      Wrapper.wrap(b).should == b
    end
    
    it "can wrap an ObjectID" do
      i = Mongo::ObjectID.new
      Wrapper.wrap(i).should == i
    end
  
    it "can wrap the time" do
      t = Time.now
      Wrapper.wrap(t).should == t
    end
    
    it "can wrap a Mongo code object (if we ever need to)" do
      c = Mongo::Code.new('5')
      Wrapper.wrap(c).should == c
    end
    
    it "can wrap a Mongo DBRef (if we ever need to)" do
      d = Mongo::DBRef.new('foo', Mongo::ObjectID.new)
      Wrapper.wrap(d).should == d
    end
    
    it "can wrap a date as a time" do
      d = Date.today
      Wrapper.wrap(d).should == Date.today.to_time
    end
      
  
  end
end