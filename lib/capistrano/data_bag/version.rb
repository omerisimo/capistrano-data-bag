module Capistrano
  module DataBag
    unless defined?(::Capistrano::DataBag::VERSION)
      VERSION = "0.0.1".freeze
    end
  end
end
