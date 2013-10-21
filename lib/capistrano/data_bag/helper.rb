require "json"

module Capistrano
  module DataBag
    module Helper
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
          item_json = load_json("#{data_bags_path}/#{bag}/#{item_file}")
          data_bag[item_json[:id].to_sym] = item_json.reject {|key, value| key == :id}
        end
        data_bag
      end

      def load_json(file_path)
        json_value = nil
        File.open(file_path, "r" ) do |f|
          json_value = JSON.load(f, nil, {:symbolize_names => true})
        end if File.exists?(file_path)
        json_value
      end
    end
  end
end
