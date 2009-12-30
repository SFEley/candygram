# A test class that we can make deliveries with and easily check results.
class Explosive
  include Candygram::Delivery
  attr_accessor :weight
  
  def kaboom
    "An earth-shattering kaboom!"
  end
  
  def repeated_kaboom(planet, repeat)
    "A #{planet}-shattering kaboom #{repeat} times!"
  end
  
  def object_kaboom(planet, repeat, object)
    "A #{planet}-shattering kaboom #{repeat} times using a #{object.class.name}!"
  end
  
  # To test that locking is performed properly
  def slow_kaboom
    sleep(5)
    "Waited 5 seconds...  NOW we kaboom."
  end
end
