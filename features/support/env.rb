require 'rack/test'
require 'rspec/core'
require 'rspec/mocks'
require 'cucumber/rspec/doubles'
require 'regenwolke_manager'
require 'pry'

Dir.mkdir('regenwolke') unless File.exists?('regenwolke')

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.syntax = :should
  end
end

World(Rack::Test::Methods)

def app
  RegenwolkeManager
end


Before do
  Celluloid.shutdown
  Celluloid.boot
  @storage = Nestene::MemoryStorage.new
  Nestene::start_nestene(@storage)
  RegenwolkeAutons::Core.init()
end
