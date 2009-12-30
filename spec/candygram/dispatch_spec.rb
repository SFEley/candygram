require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module Candygram
  describe Candygram::Dispatch do
    def run_dispatch(cycles=1)
      d = Dispatch.new(:frequency => 1)
      t = Thread.new do
        d.run
      end
      sleep(cycles)
      d.finish
      t.join(2) or raise "Dispatch never completed!"
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
      Explosive.new.slow_kaboom_later
      run_dispatch(1)
      Candygram.queue.find_one(:locked => {"$exists" => true}).should_not be_nil
    end
  end
end