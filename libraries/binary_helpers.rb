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

    def checksum_from_release_file(checksums_file, artifact_name)
      line = ::File.readlines(checksums_file).find do |l|
        l.end_with?(" #{artifact_name}\n") || l.end_with?("  #{artifact_name}\n")
      end
      raise "Could not find checksum for #{artifact_name} in #{checksums_file}" if line.nil?

      checksum = line.split.first
      raise "Invalid checksum format for #{artifact_name}" unless checksum.match?(/\A[a-fA-F0-9]{64}\z/)

      checksum
    end

    def read_checksum_file(path)
      return nil unless ::File.exist?(path)

      ::File.read(path).strip
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
