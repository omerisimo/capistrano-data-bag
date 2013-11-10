require "json"

module Capistrano
  module DataBag
    module DSL
      def self.load_into(capistrano_configuration)        
        capistrano_configuration.load do
          def create_data_bag_item(bag, item, data = {})
            FileUtils.makedirs "#{data_bags_path}/#{bag}" unless Dir.exist? "#{data_bags_path}/#{bag}"
            data_bag_item_file = "#{data_bags_path}/#{bag}/#{item}.json"
            File.open(data_bag_item_file, "w") do |f|
              f.write JSON.pretty_generate(data.merge!(id: item))
            end
            puts "Created a new data bag item at: #{data_bag_item_file}"
          end

          def load_data_bag(bag)
            return nil unless Dir.exist? "#{data_bags_path}/#{bag}"
            data_bag = {}
            item_files = Dir.entries("#{data_bags_path}/#{bag}").select! {|f| f =~ /\A*\.json\z/i}
            item_files.each do |item_file|
              item_json = Capistrano::DataBag::Support.load_json("#{data_bags_path}/#{bag}/#{item_file}")
              data_bag[item_json[:id].to_sym] = item_json.reject {|key, value| key == :id}
            end
            data_bag
          end
        end
      end
    end
  end
end
