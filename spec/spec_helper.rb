require 'coveralls'
Coveralls.wear!

require 'capistrano-spec'
require 'capistrano-data-bag'

TEMP_PATH = "#{Dir.pwd}/spec/temp"
DATA_BAG_PATH = File.expand_path(TEMP_PATH + "/data-bags", __FILE__)

RSpec.configure do |config|
  config.include Capistrano::Spec::Matchers
  config.include Capistrano::Spec::Helpers
end

RSpec.configure do |config|
  config.before(:each) do
    STDOUT.stub(:puts) #suppress all STDOUT output
    Dir.mkdir(File.expand_path(TEMP_PATH, __FILE__))
  end

  config.after(:each) do
    FileUtils.rm_r File.expand_path(TEMP_PATH, __FILE__)
  end
end
