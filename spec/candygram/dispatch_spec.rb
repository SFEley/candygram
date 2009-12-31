require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Candygram
  describe Candygram::Dispatch do
    before(:each) do
      c = Mongo::Connection.new
      d = Mongo::DB.new(DEFAULT_DATABASE, c)
      @queue = d.collection('candygram_queue')
      @dispatch = Dispatch.new(:frequency => 1)
      @exp = Explosive.new
    end
    
    def run_dispatch(cycles=1)
      t = Thread.new do
        @dispatch.run
      end
      sleep(cycles)
      yield if block_given?
      @dispatch.finish
      t.join(3) or raise "Dispatch never completed!"
    end
    
    it "knows how often to check the database" do
      d = Dispatch.new(:frequency => 5)
      d.frequency.should == 5
    end
    
    it "runs until aborted" do
      run_dispatch.should_not be_nil
    end
    
    it "checks the queue for new work on each cycle" do
      Candygram.queue.expects(:find).times(2..3)
      run_dispatch(2.5)
    end
    
    it "locks any jobs it finds" do
      @exp.slow_kaboom_later
      run_dispatch(2) do
        @queue.find_one(:locked => {"$exists" => true}).should_not be_nil
      end
    end
    
    it "forks a runner for its work" do
      pid = Process.pid
      @exp.slow_kaboom_later
      run_dispatch(2) do
        j = @queue.find_one(:locked => {"$exists" => true})
        j["status"][0]["pid"].should_not == pid
      end
    end
    
    it "keeps track of its runners" do
      3.times { @exp.slow_kaboom_later; sleep 1 }
      run_dispatch(2) do
        @dispatch.runners['Explosive'].length.should == 3
      end
    end
    
    it "runs the method" do
      @exp.kaboom_later
      run_dispatch
      j = @queue.find_one('result' => {'$exists' => true})
      j["result"].should == "An earth-shattering kaboom!"
    end
    
    it "unlocks the delivery upon completion" do
      @exp.kaboom_later
      run_dispatch
      j = @queue.find_one('result' => {'$exists' => true})
      j["locked"].should be_nil
    end
    
    it "clears the runner record when it's done working" do
      3.times { @exp.kaboom_later }
      run_dispatch
      sleep(1)
      @dispatch.runners['Explosive'].should be_empty
    end
      
  end
end