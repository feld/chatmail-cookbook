# Custom resource for managing the lego binary with version checking, download,
# checksum verification, and installation

resource_name :lego_binary
provides :lego_binary

property :version, String, name_property: true
property :install_path, String, default: '/usr/bin/lego'
property :checksums_url, String, default: lazy { "https://github.com/go-acme/lego/releases/download/#{version}/lego_#{version.delete_prefix('v')}_checksums.txt" }
property :os_name, String, default: lazy { node['os'] }
property :arch_name, String, default: lazy {
  case node['kernel']['machine']
  when 'x86_64', 'amd64'
    'amd64'
  when 'aarch64', 'arm64'
    'arm64'
  when 'armv7l'
    'arm'
  when 'i386'
    '386'
  else
    node['kernel']['machine']
  end
}

action :install do
  lego_version = new_resource.version
  install_path = new_resource.install_path
  os_name = new_resource.os_name
  arch_name = new_resource.arch_name
  lego_version_for_checksums = lego_version.delete_prefix('v')
  
  tarball_name = "lego_#{lego_version}_#{os_name}_#{arch_name}.tar.gz"
  download_url = "https://github.com/go-acme/lego/releases/download/#{lego_version}/#{tarball_name}"

  # Check if the correct version is already installed
  correct_version_installed = false
  if ::File.exist?(install_path)
    begin
      current_version_cmd = Mixlib::ShellOut.new("#{install_path} --version")
      current_version_cmd.run_command
      if current_version_cmd.stdout && current_version_cmd.stdout.include?(lego_version.gsub('v', ''))
        correct_version_installed = true
        Chef::Log.info("Correct version of lego (#{lego_version}) already installed")
      end
    rescue
      # If there's an error running the command, assume version check failed
      Chef::Log.warn("Error checking installed lego version, will proceed with installation")
    end
  end

  # Only proceed with download/verification if correct version isn't installed
  unless correct_version_installed
    # Check if the checksums file already exists and contains the expected entry
    ruby_block 'check_and_validate_checksums_file' do
      block do
        checksums_file = "/tmp/lego_#{lego_version_for_checksums}_checksums.txt"
        # Check if the checksums file exists and contains the expected entry
        if ::File.exist?(checksums_file)
          begin
            checksums_content = ::File.read(checksums_file)
            # Check if file is properly formatted and contains expected entry
            if checksums_content.include?("#{tarball_name}") && checksums_content.lines.any? { |line| line.match(/[a-fA-F0-9]{64}[\s]+#{Regexp.escape(tarball_name)}$/) }
              # File exists, appears valid, and contains expected entry, no need to download
              Chef::Log.info("Checksums file already exists and contains valid entry for #{tarball_name}")
            else
              # File exists but doesn't contain our tarball entry or is not properly formatted, delete it
              Chef::Log.warn("Checksums file doesn't contain valid entry for #{tarball_name} or is malformed, deleting")
              ::File.delete(checksums_file) if ::File.exist?(checksums_file)
            end
          rescue => e
            # File exists but can't be read properly, delete it
            Chef::Log.warn("Error reading checksums file: #{e.message}, deleting")
            ::File.delete(checksums_file) if ::File.exist?(checksums_file)
          end
        end
      end
    end

    # Download the checksums file
    remote_file "/tmp/lego_#{lego_version_for_checksums}_checksums.txt" do
      source new_resource.checksums_url
      owner 0
      group 0
      mode '0644'
      only_if { !::File.exist?("/tmp/lego_#{lego_version_for_checksums}_checksums.txt") || 
                (::File.exist?("/tmp/lego_#{lego_version_for_checksums}_checksums.txt") && 
                !::File.read("/tmp/lego_#{lego_version_for_checksums}_checksums.txt").include?("#{tarball_name}")) }
    end

    # Download the lego binary
    remote_file "/tmp/#{tarball_name}" do
      source download_url
      owner 0
      group 0
      mode '0644'
      not_if { ::File.exist?("/tmp/#{tarball_name}") }
    end

    # Verify checksum and extract the tarball
    execute 'verify_and_extract_lego' do
      command <<-CMD
        cd /tmp && \\
        grep #{tarball_name} lego_#{lego_version_for_checksums}_checksums.txt | sha256sum -c - && \\
        tar -xzf #{tarball_name} -C /tmp && \\
        mv /tmp/lego #{install_path} && \\
        chmod 0555 #{install_path}
      CMD
      only_if { ::File.exist?("/tmp/#{tarball_name}") && ::File.exist?("/tmp/lego_#{lego_version_for_checksums}_checksums.txt") }
    end
  end
end
