require "json"

module Capistrano
  module DataBag
    module Support
      def self.load_json(file_path)
        json_value = nil
        File.open(file_path, "r" ) do |f|
          json_value = JSON.load(f, nil, {:symbolize_names => true})
        end if File.exists?(file_path)
        json_value
      end
    end
  end
end
