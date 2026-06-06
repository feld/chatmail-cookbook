# Custom resource for managing the filtermail binary with version checking, download,
# checksum verification, and installation

resource_name :filtermail_binary
provides :filtermail_binary
unified_mode true

property :version, String, name_property: true
property :install_path, String, required: true
property :os_name, String, default: lazy { node['os'] }
property :arch_name, String, default: lazy {
  case node['kernel']['machine']
  when 'x86_64', 'amd64'
    'x86_64'
  when 'aarch64', 'arm64'
    'aarch64'
  else
    raise 'filtermail only distributes aarch64 and x86_64 binaries for Linux'
  end
}
property :checksums, Hash, default: lazy { node['filtermail']['checksums'] }

action :install do
  # Handle based on platform
  if platform_family?('freebsd')
    # On FreeBSD, install the filtermail package from custom repo
    package 'filtermail'
    return
  end

  # On Linux, continue with the download approach
  filtermail_version = new_resource.version
  install_path = new_resource.install_path
  arch_name = new_resource.arch_name
  checksums = new_resource.checksums

  # Determine the binary name based on architecture
  binary_name = "filtermail-#{arch_name}"
  download_url = "https://github.com/chatmail/filtermail/releases/download/#{filtermail_version}/#{binary_name}"
  downloaded_path = "#{Chef::Config[:file_cache_path]}/#{binary_name}-#{filtermail_version}"

  # Get the expected checksum
  expected_checksum = checksums[arch_name]

  if checksum_match?(install_path, expected_checksum)
    Chef::Log.info("Correct filtermail checksum already installed at #{install_path}, skipping download/install")
  else
    # If checksum is not available, fall back to version check for idempotence
    correct_version_installed = false
    if expected_checksum.nil? && ::File.exist?(install_path)
      begin
        current_version_cmd = Mixlib::ShellOut.new("#{install_path} --version")
        current_version_cmd.run_command
        if current_version_cmd.stdout && current_version_cmd.stdout.include?(filtermail_version.delete_prefix('v'))
          correct_version_installed = true
          Chef::Log.info("Correct version of filtermail (#{filtermail_version}) already installed")
        end
      rescue
        # If there's an error running the command, assume version check failed
        Chef::Log.warn('Error checking installed filtermail version, will proceed with installation')
      end
    end

    unless correct_version_installed
      remote_file downloaded_path do
        source download_url
        owner 0
        group 0
        mode '0644'
        action :create_if_missing
      end

      ruby_block 'verify_and_install_filtermail' do
        block do
          if !expected_checksum.nil? && !checksum_match?(downloaded_path, expected_checksum)
            actual_checksum = sha256_for_file(downloaded_path)
            raise "Checksum mismatch for #{binary_name}: expected #{expected_checksum}, got #{actual_checksum}"
          end

          install_binary(downloaded_path, install_path)
        end
        only_if { ::File.exist?(downloaded_path) }
      end
    end
  end
end
