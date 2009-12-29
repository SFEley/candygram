# A simple, non-Candygrammed class to test argument encoding
class Missile
  attr_accessor :payload
  attr_accessor :rocket
  
  def explode
    "Dropped the #{payload}."
  end
end

