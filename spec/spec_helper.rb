$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'candygram'
require 'spec'
require 'spec/autorun'

# Override the default database so that we don't clobber any production queues by chance
Candygram.const_set(:DEFAULT_DATABASE, "candygram_test")

Spec::Runner.configure do |config|
  config.after(:each) {Candygram.connection.drop_database(Candygram::DEFAULT_DATABASE)}
end
