require "spec_helper"
require 'securerandom'

describe Capistrano::DataBag::DSL do
  before do
    @configuration = Capistrano::Configuration.new
    @configuration.set(:data_bags_path, DATA_BAG_PATH)
  end

  subject do
    Capistrano::DataBag::DSL.load_into(@configuration)
    @configuration
  end

  describe "#create_data_bag_item" do
    it "it creates the data bag directory if it doesn't exist" do
      subject.create_data_bag_item("new_bag", "item")
      Dir.exist?("#{DATA_BAG_PATH}/new_bag").should be_true
    end

    it "it does not create the data bag directory if it exist" do
      FileUtils.makedirs "#{DATA_BAG_PATH}/existing_bag"
      FileUtils.should_not_receive(:makedirs).with("#{DATA_BAG_PATH}/existing_bag")
      subject.create_data_bag_item("existing_bag", "item")
    end

    it "creates the data bag item file as JSON" do
      subject.create_data_bag_item("my_bag", "my_item")
      File.exist?("#{DATA_BAG_PATH}/my_bag/my_item.json").should be_true
    end

    it "writes the data to the data bag item file" do
      subject.create_data_bag_item("my_bag", "my_item", {field1: "value1", field2: "value2"})
      file_content = JSON.parse IO.read("#{DATA_BAG_PATH}/my_bag/my_item.json")
      file_content.should == {"id" => "my_item", "field1" => "value1", "field2" => "value2"}
    end
  end

  describe "#create_encrypted_data_bag_item" do
    before do
      Capistrano::DataBag::Support.stub(:encrypt_data_bag_item).and_return("{encrypted_data}")
      subject.stub(:create_data_bag_item)
    end
    it "loads the data bag secret if no secret is passed" do
      subject.should_receive(:load_data_bag_secret)
      subject.create_encrypted_data_bag_item("new_bag", "item",{})
    end

    it "encrypts the data content" do
      Capistrano::DataBag::Support.should_receive(:encrypt_data_bag_item).with("plain_data", "secret").and_return("{encrypted_data}")
      subject.create_encrypted_data_bag_item("new_bag", "item", "plain_data", "secret")
    end

    it "creates the data bag item with the encrypted content" do
      subject.should_receive(:create_data_bag_item).with("new_bag", "item","{encrypted_data}")
      subject.create_encrypted_data_bag_item("new_bag", "item", "plain_data", "secret")
    end
  end

  describe "#load_data_bag" do
    it "returns nil if no data bag exist" do
      subject.load_data_bag("my_bag").should be_nil
    end

    it "returns an empty array if there are no items in the bag directory" do
      FileUtils.makedirs "#{DATA_BAG_PATH}/my_bag"
      subject.load_data_bag("my_bag").should == {}
    end

    it "returns a hash of the data bag items and their values" do
      subject.create_data_bag_item("my_bag", "my_item1", {field1: "value1", field2: "value2"})
      subject.create_data_bag_item("my_bag", "my_item2", {field3: "value3", field4: "value4"})
      subject.load_data_bag("my_bag").should == {
        my_item1: {field1: "value1", field2: "value2"},
        my_item2: {field3: "value3", field4: "value4"},
      }
    end

    it "decrypts the data bag item with supplied secret if content is encrypted" do
      subject.create_encrypted_data_bag_item("my_bag", "my_item1", {field1: "value1", field2: "value2"} ,"secret")
      subject.load_data_bag("my_bag", "secret").should == {
        my_item1: {field1: "value1", field2: "value2"},
      }
    end

    it "decrypts the data bag item and loads secret if no secret is passed" do
      subject.should_receive(:load_data_bag_secret).and_return("secret")
      subject.create_encrypted_data_bag_item("my_bag", "my_item1", {field1: "value1", field2: "value2"} ,"secret")
      subject.load_data_bag("my_bag").should == {
        my_item1: {field1: "value1", field2: "value2"},
      }
    end
  end

  describe "#load_data_bag_secret" do
    it "raises an error if no path is set or given" do
      expect {
        subject.load_data_bag_secret
      }.to raise_error(ArgumentError, /You must supply a secret file path/)
    end

    it "returns the striped content of the secret file path argument" do
      IO.should_receive(:read).with("secrete/file/path").and_return(" Very secret content! ")
      subject.load_data_bag_secret("secrete/file/path").should == "Very secret content!"
    end

    it "reads the file set in :data_bag_secret config variable" do
      subject.set(:data_bag_secret, "secrete/file/path")
      IO.should_receive(:read).with("secrete/file/path").and_return("")
      subject.load_data_bag_secret
    end
  end
end