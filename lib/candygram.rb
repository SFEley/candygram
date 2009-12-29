module Candygram
  DEFAULT_DATABASE = 'candygram'
  DEFAULT_QUEUE = 'candygram_queue'
  DEFAULT_QUEUE_SIZE = 10 * 1024 * 1024  # 10 MB
end

require 'mongo'
require 'candygram/connection'
require 'candygram/delivery'