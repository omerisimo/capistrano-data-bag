require "spec_helper"

describe Capistrano::DataBag::Support do
  describe ".load_json" do
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