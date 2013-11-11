require "json"
require 'openssl'
require 'base64'

module Capistrano
  module DataBag
    module Support
      ENCRYPTOR_ALGORITHM = 'aes-256-cbc'
      ENCRYPTOR_VERSION = 1

      def self.load_json(file_path)
        json_value = nil
        File.open(file_path, "r" ) do |f|
          json_value = JSON.load(f, nil, {:symbolize_names => true})
        end if File.exists?(file_path)
        json_value
      end

      def self.encrypt_data_bag_item(plain_hash, secret)
        encrtpyed_hash = {}
        plain_hash.each do |(key, val)|
          encrtpyed_hash[key] = key.to_s != "id" ? encrypt_value(val, secret) : val
        end
        encrtpyed_hash
      end

      private

      def self.encrypt_value(plain_value, key)
        encryptor = OpenSSL::Cipher::Cipher.new(ENCRYPTOR_ALGORITHM)
        encryptor.encrypt
        iv = encryptor.iv = encryptor.random_iv
        encryptor.key = Digest::SHA256.digest(key)
        encrypted_value = encryptor.update(plain_value) + encryptor.final

        return {
          "encrypted_data" => Base64.encode64(encrypted_value),
          "iv" => Base64.encode64(iv),
          "version" => ENCRYPTOR_VERSION,
          "cipher" => ENCRYPTOR_ALGORITHM
        }
      end
    end
  end
end
