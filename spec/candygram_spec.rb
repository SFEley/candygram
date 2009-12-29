require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Candygram do
  it "creates a default connection" do
    Candygram.connection.host.should == 'localhost'
    Candygram.connection.port.should == 27017
  end
  
  it "accepts an explicit connection" do
    this = Mongo::Connection.new 'db.mongohq.com'  # Works as of time of writing
    Candygram.connection = this
    Candygram.connection.host.should == 'db.mongohq.com'
  end
  
  it "has a default database" do
    Candygram.database.should == 'candygram_test'
  end
  
  it "accepts a new database name" do
    Candygram.database = 'candygram_foo'
    Candygram.db.name.should == 'candygram_foo'
  end

  it "accepts an actual DB object" do
    d = Mongo::DB.new('candygram_bar', Candygram.connection)
    Candygram.db = d
    Candygram.database.should == 'candygram_bar'
  end
  
  it "creates a default queue" do
    Candygram.queue.name.should == "candygram_queue"
    Candygram.queue.options['capped'].should be_true
  end
  
  it "accepts another collection for the queue" do
    Candygram.queue = Candygram.db.create_collection('foo')
    Candygram.queue.name.should == 'foo'
  end

  it "can create a collection for the queue" do
    q = Candygram.create_queue('bar')
    q.should be_a_kind_of(Mongo::Collection)
    q.options['capped'].should be_true
  end
  
  after(:each) do  # Clear state from our tests
    Candygram.queue = nil
    Candygram.db = nil
    Candygram.connection = nil
  end
  
end