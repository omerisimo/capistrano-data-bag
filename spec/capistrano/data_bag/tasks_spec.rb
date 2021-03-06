require "spec_helper"
require 'capistrano'

describe Capistrano::DataBag::Tasks do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.extend(Capistrano::Spec::ConfigurationExtension)
  end

  subject do
    Capistrano::DataBag::Tasks.load_into(@configuration)
    @configuration
  end

  context "loaded into configuration" do
    it "sets default attributes" do
      @configuration.should_receive(:set).with(:data_bags_path, "./config/deploy/data-bags")
      Capistrano::DataBag::Tasks.load_into(@configuration)
    end
  end

  describe "task" do
    shared_examples_for "a :create task" do
      before do
        subject.stub(:create_data_bag_item)
      end

      context "with command line arguments" do
        before do
          subject.set(:data_bag_name, "bag")
          subject.set(:data_bag_item, "item")
          subject.set(:data_file, "./data_file.json")
        end

        it "loads the data from the json file" do
          Capistrano::DataBag::Support.should_receive(:load_json).with("./data_file.json")
          subject.find_and_execute_task(create_task)
        end

        it "creates the data bag item with the supplied parameters" do
          Capistrano::DataBag::Support.should_receive(:load_json).with("./data_file.json").and_return({a: "1", b: [1,2,3]})
          subject.should_receive(:create_data_bag_item).with("bag", "item", {a: "1", b: [1,2,3]})

          subject.find_and_execute_task(create_task)
        end
      end
      context "with UI input" do
        before do
          Capistrano::CLI.ui.stub(:ask).and_return("")
        end
        it "asks for the data bag name if it does not exist" do
          subject.set(:data_bag_item, "item")
          Capistrano::CLI.ui.should_receive(:ask).and_return("my_bag")

          subject.find_and_execute_task(create_task)

          subject.data_bag_name.should == "my_bag"
        end

        it "asks for the item name if it does not exist" do
          subject.set(:data_bag_name, "bag")
          Capistrano::CLI.ui.should_receive(:ask).and_return("my_item")

          subject.find_and_execute_task(create_task)

          subject.data_bag_item.should == "my_item"
        end

        describe "handling item data input" do
          before do
            subject.set(:data_bag_name, "bag")
            subject.set(:data_bag_item, "item")
            Capistrano::CLI.ui.should_receive(:ask).with("Enter key: ").and_return("key_1")
            Capistrano::CLI.ui.should_receive(:ask).with("Enter value for key_1: ").and_return("value_1")
            Capistrano::CLI.ui.should_receive(:ask).with("Enter key: ").and_return("key_2")
            Capistrano::CLI.ui.should_receive(:ask).with("Enter value for key_2: ").and_return("value_2")
            Capistrano::CLI.ui.should_receive(:ask).with("Enter key: ").and_return("")
          end

          it "asks for key value pairs as item's data until an empty key is entered" do
            subject.find_and_execute_task(create_task)
          end

          it "creates the data bag item with the supplied arguments" do
            subject.should_receive(:create_data_bag_item).with("bag", "item", {"key_1" => "value_1", "key_2"=> "value_2"})
            subject.find_and_execute_task(create_task)
          end
        end
      end
    end

    describe 'data_bag:create' do
      let (:create_task) { 'data_bag:create' }
      it_behaves_like "a :create task"
    end

    describe 'data_bag:encrypted:create' do
      let (:create_task) { 'data_bag:encrypted:create' }
      before do
        subject.set(:data_bag_secret, "secret_file_path")
        IO.stub(:read).with("secret_file_path").and_return(" secret ")

        # in each test expect to encrpyt the data
        Capistrano::DataBag::Support.should_receive(:encrypt_data_bag_item) do |data, secret|
          data.should be_a(Hash)
          secret.should == "secret"
          # return the same data to make assertion easier with the normal create task
          data
        end
      end
      it_behaves_like "a :create task"
    end

    describe 'data_bag:show' do
      it "asks for the data bag name if it does not exist" do
        Capistrano::CLI.ui.should_receive(:ask).with("Enter data bag name: ").and_return("my_bag")

        subject.find_and_execute_task('data_bag:show')

        subject.data_bag_name.should == "my_bag"
      end

      it "loads the data bag" do
        subject.set(:data_bag_name, "bag")
        subject.should_receive(:load_data_bag).with("bag")

        subject.find_and_execute_task('data_bag:show')
      end

      it "prints the data bag content" do
        subject.set(:data_bag_name, "bag")
        subject.should_receive(:load_data_bag).with("bag").and_return({bag1: {key1: "value1", key2: "value2"}, bag2: {key3: "value3"}})
        Capistrano::CLI.ui.should_receive(:say).with(/#{JSON.pretty_generate({bag1: {key1: "value1", key2: "value2"}, bag2: {key3: "value3"}})}/)

        subject.find_and_execute_task('data_bag:show')
      end
    end
  end
end