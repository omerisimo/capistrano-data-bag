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
      encrypted_item = subject.encrypt_data_bag_item({id: "my_id"}, "secret")
      encrypted_item[:id] = "my_id"
    end

    it "encrypts each value and returns a hash of the encrypted data" do
      # Stub the random IV to get a consistent encryption value
      OpenSSL::Cipher::Cipher.any_instance.stub(:random_iv).and_return("\x05\x99\tEm\x04YR\xDB\x0E'\xC5\xFF\e@\xE4")

      encrypted_item = subject.encrypt_data_bag_item({id: "my_id", val1: "value_1", val2: "value_2"}, "secret")
      encrypted_item.should == {
        id: "my_id",
        val1: {
          :encrypted_data => "kBMXDW6E0h51G3IXXyYI/A==\n",
          :iv => "BZkJRW0EWVLbDifF/xtA5A==\n",
          :version => Capistrano::DataBag::Support::ENCRYPTOR_VERSION,
          :cipher => Capistrano::DataBag::Support::ENCRYPTOR_ALGORITHM
        },
        val2: {
          :encrypted_data => "+kGY+mu09gK2KU5qjkcIcw==\n",
          :iv => "BZkJRW0EWVLbDifF/xtA5A==\n",
          :version => Capistrano::DataBag::Support::ENCRYPTOR_VERSION,
          :cipher => Capistrano::DataBag::Support::ENCRYPTOR_ALGORITHM
        }
      }
    end
  end

  describe ".decrypt_data_bag_item" do
    it "does not decrypt plain values" do
      subject.decrypt_data_bag_item({id: "my_id", val1: "value_1"}, "secret").should == {id: "my_id", val1: "value_1"}
    end

    it "decrypts encrypted values" do
      plain_data_bag_item = {id: "my_id", val1: "value_1", val2: "value_2"}
      encrypted_data_bag_item = subject.encrypt_data_bag_item(plain_data_bag_item, "secret")
      subject.decrypt_data_bag_item(encrypted_data_bag_item, "secret").should == plain_data_bag_item
    end
  end

  describe ".is_data_bag_item_encrypted?" do
    it "returns false if none of the values are encrypted" do
      subject.is_data_bag_item_encrypted?({is: "id", val1: "value1", val2: "value2"}).should be_false
    end

    it "returns true if any of the values are encrypted" do
      subject.is_data_bag_item_encrypted?({
        id: "my_id",
        val1: "value1",
        val2: {
          :encrypted_data => "encrypted_data",
          :iv => "iv",
          :version => Capistrano::DataBag::Support::ENCRYPTOR_VERSION,
          :cipher => Capistrano::DataBag::Support::ENCRYPTOR_ALGORITHM
        }
      }).should be_true
    end
  end
end