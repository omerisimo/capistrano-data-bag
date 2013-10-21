require 'coveralls'
Coveralls.wear!

require 'capistrano-spec'
require 'capistrano-data-bag'

RSpec.configure do |config|
  config.include Capistrano::Spec::Matchers
  config.include Capistrano::Spec::Helpers
end