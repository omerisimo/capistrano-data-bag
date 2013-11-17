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

      def self.decrypt_data_bag_item(encrypted_hash, secret)
        plain_hash = {}
        encrypted_hash.each do |key, val|
          plain_hash[key] = is_value_encrypted?(val) ? decrypt_value(val, secret) : val
        end
        plain_hash
      end

      def self.is_data_bag_item_encrypted?(data_bag_item)
        data_bag_item.any? { |key, value| is_value_encrypted?(value) }
      end
      private

      def self.encrypt_value(plain_value, key)
        encryptor = OpenSSL::Cipher::Cipher.new(ENCRYPTOR_ALGORITHM)
        encryptor.encrypt
        iv = encryptor.iv = encryptor.random_iv
        encryptor.key = Digest::SHA256.digest(key)

        wrapped_value = { value: plain_value } # wrap the value in a hash, because values like strings and integers cannot be parsed to valid JSON
        encrypted_value = encryptor.update(wrapped_value.to_json) + encryptor.final

        return {
          :encrypted_data => Base64.encode64(encrypted_value),
          :iv => Base64.encode64(iv),
          :version => ENCRYPTOR_VERSION,
          :cipher => ENCRYPTOR_ALGORITHM
        }
      end

      def self.decrypt_value(encrypted_value, key)
        decryptor = OpenSSL::Cipher::Cipher.new(encrypted_value[:cipher])
        decryptor.decrypt
        decryptor.iv = Base64.decode64(encrypted_value[:iv])
        decryptor.key = Digest::SHA256.digest(key)

        wrapped_value = decryptor.update(Base64.decode64(encrypted_value[:encrypted_data])) + decryptor.final
        JSON.parse(wrapped_value, :symbolize_names => true)[:value] # Parse the wrapped value and return the value of the wrapper
      end

      def self.is_value_encrypted?(value)
        value.is_a?(Hash) && value[:cipher] && value[:encrypted_data] && value[:iv] && value[:version]
      end
    end
  end
end
