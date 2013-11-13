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
            Capistrano::CLI.ui.say "Created a new data bag item at: #{data_bag_item_file}"
          end

          def create_encrypted_data_bag_item(bag, item, data = {}, secret = nil)
            secret ||= load_data_bag_secret
            encrypted_data = Capistrano::DataBag::Support.encrypt_data_bag_item(data, secret)
            create_data_bag_item(bag, item, encrypted_data)
          end

          def load_data_bag(bag, secret = nil)
            return nil unless Dir.exist? "#{data_bags_path}/#{bag}"
            data_bag = {}
            item_files = Dir.entries("#{data_bags_path}/#{bag}").select! {|f| f =~ /\A*\.json\z/i}
            item_files.each do |item_file|
              item_json = Capistrano::DataBag::Support.load_json("#{data_bags_path}/#{bag}/#{item_file}")
              if Capistrano::DataBag::Support.is_data_bag_item_encrypted?(item_json)
                secret ||= load_data_bag_secret
                item_json = Capistrano::DataBag::Support.decrypt_data_bag_item(item_json, secret)
              end
              data_bag[item_json[:id].to_sym] = item_json.reject {|key, value| key == :id}
            end
            data_bag
          end

          def load_data_bag_secret(data_bag_secret = nil)
            data_bag_secret ||= fetch(:data_bag_secret, nil)
            throw ArgumentError.new("You must supply a secret file path. (Hint: set :data_bag_secret, 'secret/file/path')") unless data_bag_secret
            IO.read(data_bag_secret).strip
          end
        end
      end
    end
  end
end
