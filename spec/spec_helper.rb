require 'coveralls'
Coveralls.wear!

require 'capistrano-spec'
require 'capistrano-data-bag'

RSpec.configure do |config|
  config.include Capistrano::Spec::Matchers
  config.include Capistrano::Spec::Helpers
end

RSpec.configure do |config|
  config.before(:each) do
    STDOUT.stub(:puts) #suppress all STDOUT output
  end
end
