require 'digest'
require 'fileutils'

module ChatmailCookbook
  module BinaryHelpers
    def sha256_for_file(path)
      return nil unless ::File.exist?(path)

      Digest::SHA256.file(path).hexdigest
    end

    def checksum_match?(path, expected_checksum)
      return false if expected_checksum.nil?

      actual_checksum = sha256_for_file(path)
      return false if actual_checksum.nil?

      actual_checksum.casecmp?(expected_checksum.to_s)
    end

    def install_binary(downloaded_path, install_path)
      FileUtils.mv(downloaded_path, install_path)
      FileUtils.chmod(0o555, install_path)
    end
  end
end

Chef::Recipe.include(ChatmailCookbook::BinaryHelpers)
Chef::Resource.include(ChatmailCookbook::BinaryHelpers)
Chef::Provider.include(ChatmailCookbook::BinaryHelpers)
