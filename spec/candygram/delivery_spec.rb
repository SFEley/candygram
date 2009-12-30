require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Candygram::Delivery do

  before(:each) do
    @this = Explosive.new
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
  
  it "sets the time it was created" do
    id = @this.kaboom_later
    (Time.now.utc - Candygram.queue.find_one(id)['created_at']).should < 2
  end
  
  it "wraps itself up as its own package" do
    @this.weight = 15
    id = @this.kaboom_later
    unwrap = Candygram::Wrapper.unwrap(Candygram.queue.find_one(id)['package'])
    unwrap.should be_an(Explosive)
    unwrap.weight.should == 15
  end
  
  describe "for _later" do
    it "can queue a method call using _later" do
      @this.kaboom_later.should_not be_nil
    end

    it "sets the time for delivery to now" do
      id = @this.kaboom_later
      (Time.now.utc - Candygram.queue.find_one(id)['deliver_at']).should < 2
    end
    
  end

end