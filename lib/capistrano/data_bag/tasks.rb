require 'capistrano'
require 'capistrano/cli'
require 'capistrano/version'

module Capistrano
  module DataBag
    class Tasks
      def self.load_into(capistrano_config)
        Capistrano::DataBag::DSL.load_into(capistrano_config)
        capistrano_config.load do

          set :data_bags_path, "./config/deploy/data-bags" unless exists?(:data_bags_path)

          namespace :data_bag do
            desc 'Create a new data bag'
            task :create do
              data = read_create_data_bag_information
              create_data_bag_item(data_bag_name, data_bag_item, data)
            end

            desc 'Show the content of a data bag'
            task :show do
              set(:data_bag_name, Capistrano::CLI.ui.ask("Enter data bag name: ")) unless exists?(:data_bag_name)
              puts load_data_bag(data_bag_name)
            end

            namespace :encrypted do
              task :create do
                secret = load_data_bag_secret
                data = read_create_data_bag_information
                create_encrypted_data_bag_item(data_bag_name, data_bag_item, data, secret)
              end
            end
          end

          def self.read_create_data_bag_information
            set(:data_bag_name, Capistrano::CLI.ui.ask("Enter data bag name: ")) unless exists?(:data_bag_name)
            set(:data_bag_item, Capistrano::CLI.ui.ask("Enter item name: ")) unless exists?(:data_bag_item)

            if exists?(:data_file)
              data = Capistrano::DataBag::Support.load_json(data_file) || {}
            else
              data = {}
              begin
                key = Capistrano::CLI.ui.ask "Enter key: "
                value = Capistrano::CLI.ui.ask "Enter value for #{key}: " unless key.empty?
                data.merge! key => value unless key.empty?
              end until key.empty?
              data
            end
          end
        end
      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::DataBag::Tasks.load_into(Capistrano::Configuration.instance)
end
