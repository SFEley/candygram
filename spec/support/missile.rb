# A simple, non-Candygrammed class to test argument encoding
class Missile
  attr_accessor :payload
  
  def explode
    "Dropped the #{payload}."
  end
end

