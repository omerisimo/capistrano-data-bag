require "spec_helper"

describe Capistrano::DataBag::Helper do
  TEMP_PATH = "../../../temp"
  DATA_BAG_PATH = File.expand_path(TEMP_PATH + "/data-bags", __FILE__)
  subject do
    Class.new do
      include Capistrano::DataBag::Helper
      def data_bags_path
        DATA_BAG_PATH
      end
    end.new
  end

  before do
    Dir.mkdir(File.expand_path(TEMP_PATH, __FILE__))
  end

  after do
    FileUtils.rm_r File.expand_path(TEMP_PATH, __FILE__)
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
  end

  describe "#load_json" do
    it "returns nil if no file exist" do
      subject.load_json("file.json").should be_nil
    end

    it "returns the file content as json" do
      json_object = {
          key_a: "val_a",
          key_b: [1, 2, 3],
          key_c: {a: 1, b: 2}
      }

      file_path = File.expand_path(TEMP_PATH + "/temp.json", __FILE__)
      File.open(file_path,"w") do |f|
        f.write(JSON.pretty_generate(json_object))
      end

      subject.load_json(file_path).should == json_object
    end
    
  end
end