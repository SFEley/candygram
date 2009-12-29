require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Candygram::Delivery do

  before(:each) do
    @this = Explosive.new
  end
  
  it "can queue a method call using _later" do
    @this.kaboom_later.should_not be_nil
  end
  
  it "adds the method to the delivery queue" do
    @this.kaboom_later
    Candygram.queue.find(:class => /Explosive/, :method => "kaboom").count.should == 1
  end
  
  it "captures the arguments passed to the method" do
    id = @this.repeated_kaboom_later('Venus', 15)
    doc = Candygram.queue.find_one(id)
    doc['arguments'].should == ['Venus', 15]
  end
  
  it "takes an object as an argument" do
    m = Missile.new
    id = @this.object_kaboom_later('Pluto', 6, m)
    doc = Candygram.queue.find_one(id)
    doc['arguments'][2].should be_a_kind_of(Hash)
  end
  

end