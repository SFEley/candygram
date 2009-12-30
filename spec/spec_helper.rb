$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'candygram'
require 'mocha'
require 'spec'
require 'spec/autorun'

# Override the default database so that we don't clobber any production queues by chance
Candygram.const_set(:DEFAULT_DATABASE, "candygram_test")

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

Spec::Runner.configure do |config|
  config.mock_with :mocha
  
  # "I say we take off and nuke the place from orbit. It's the only way to be sure."
  config.after(:each) {Candygram.connection.drop_database(Candygram::DEFAULT_DATABASE)}
end
