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
  when 'i386'
    '386'
  else
    node['kernel']['machine']
  end
}
property :use_musl, [true, false], default: false
property :checksums, Hash, default: lazy { node['filtermail']['checksums'] }

action :install do
  # Handle based on platform
  if platform_family?('freebsd')
    # On FreeBSD, install the filtermail package from custom repo
    package 'filtermail'
  else
    # On Linux, continue with the download approach
    filtermail_version = new_resource.version
    install_path = new_resource.install_path
    arch_name = new_resource.arch_name
    use_musl = new_resource.use_musl
    checksums = new_resource.checksums

    # Determine the binary name based on architecture and musl flag
    binary_suffix = use_musl ? "#{arch_name}-musl" : arch_name
    binary_name = "filtermail-#{binary_suffix}"
    download_url = "https://github.com/chatmail/filtermail/releases/download/#{filtermail_version}/#{binary_name}"

    # Get the expected checksum
    expected_checksum = checksums[binary_suffix]

    # Check if the correct version is already installed
    correct_version_installed = false
    if ::File.exist?(install_path)
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

    # Only proceed with download/verification if correct version isn't installed
    unless correct_version_installed
      # Download the filtermail binary
      remote_file "/tmp/#{binary_name}" do
        source download_url
        owner 0
        group 0
        mode '0644'
        action :create_if_missing
      end

      # Verify checksum and install the binary
      execute 'verify_and_install_filtermail' do
        command <<-CMD
          echo "#{expected_checksum}  /tmp/#{binary_name}" | sha256sum -c - && \\
          mv /tmp/#{binary_name} #{install_path} && \\
          chmod 0555 #{install_path}
        CMD
        only_if { ::File.exist?("/tmp/#{binary_name}") && !expected_checksum.nil? }
      end

      # If no checksum is provided, just install without verification
      execute 'install_filtermail_without_checksum' do
        command <<-CMD
          mv /tmp/#{binary_name} #{install_path} && \\
          chmod 0555 #{install_path}
        CMD
        only_if { ::File.exist?("/tmp/#{binary_name}") && expected_checksum.nil? }
      end
    end
  end
end
