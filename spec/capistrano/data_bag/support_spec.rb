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

  describe ".encrypt_data_bag_item" do
    it "does not encrypt the :id key's value" do
      encrypted_item = subject.encrypt_data_bag_item({id: "my_id"}, "secrete")
      encrypted_item[:id] = "my_id"
    end

    it "encrypts each value and returns a hash of the encrypted data" do
      # Stub the random IV to get a consistent encryption value
      OpenSSL::Cipher::Cipher.any_instance.stub(:random_iv).and_return("\x05\x99\tEm\x04YR\xDB\x0E'\xC5\xFF\e@\xE4")

      encrypted_item = subject.encrypt_data_bag_item({id: "my_id", val1: "value_1", val2: "value_2"}, "secrete")
      encrypted_item.should == {
        id: "my_id",
        val1: {
          "encrypted_data" => "ck3KbsHZNGwGQQ3qkwEqKg==\n",
          "iv" => "BZkJRW0EWVLbDifF/xtA5A==\n",
          "version" => Capistrano::DataBag::Support::ENCRYPTOR_VERSION,
          "cipher" => Capistrano::DataBag::Support::ENCRYPTOR_ALGORITHM
        },
        val2: {
          "encrypted_data" => "DyaB8O6Et1gCWwpK45bcng==\n",
          "iv" => "BZkJRW0EWVLbDifF/xtA5A==\n",
          "version" => Capistrano::DataBag::Support::ENCRYPTOR_VERSION,
          "cipher" => Capistrano::DataBag::Support::ENCRYPTOR_ALGORITHM
        }
      }
    end
  end
end