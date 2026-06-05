# Custom resource for managing the lego binary with version checking, download,
# checksum verification, and installation

resource_name :lego_binary
provides :lego_binary
unified_mode true

property :version, String, default: lazy { node['lego']['release'] }
property :install_path, String, default: lazy {
  if platform?('freebsd')
    '/usr/local/bin/lego'
  else
    '/usr/bin/lego'
  end
}
property :os_name, String, default: lazy { node['os'] }
property :arch_name, String, default: lazy {
  case node['kernel']['machine']
  when 'x86_64', 'amd64'
    'amd64'
  when 'aarch64', 'arm64'
    'arm64'
  when 'i386'
    '386'
  else
    node['kernel']['machine']
  end
}

action :install do
  if platform_family?('freebsd')
    package 'lego'
    return
  end

  unless platform?('debian')
    raise 'lego_binary is only supported on Debian and FreeBSD'
  end

  lego_version = new_resource.version
  install_path = new_resource.install_path
  os_name = new_resource.os_name
  arch_name = new_resource.arch_name
  lego_version_for_checksums = lego_version.delete_prefix('v')

  tarball_name = "lego_#{lego_version}_#{os_name}_#{arch_name}.tar.gz"
  download_url = "https://github.com/go-acme/lego/releases/download/#{lego_version}/#{tarball_name}"
  checksums_url = "https://github.com/go-acme/lego/releases/download/#{lego_version}/lego_#{lego_version_for_checksums}_checksums.txt"

  checksums_file = "#{Chef::Config[:file_cache_path]}/lego_#{lego_version_for_checksums}_checksums.txt"
  tarball_path = "#{Chef::Config[:file_cache_path]}/#{tarball_name}"

  remote_file checksums_file do
    source checksums_url
    owner 0
    group 0
    mode '0644'
    action :create_if_missing
  end

  ruby_block "extract checksum for #{tarball_name}" do
    block do
      line = ::File.readlines(checksums_file).find { |l| l.end_with?(" #{tarball_name}\n") || l.end_with?("  #{tarball_name}\n") }
      raise "Could not find checksum for #{tarball_name} in #{checksums_file}" if line.nil?

      checksum = line.split.first
      raise "Invalid checksum format for #{tarball_name}" unless checksum.match?(/\A[a-fA-F0-9]{64}\z/)

      node.run_state["lego_checksum_#{tarball_name}"] = checksum
    end
    action :run
  end

  remote_file tarball_path do
    source download_url
    checksum lazy { node.run_state["lego_checksum_#{tarball_name}"] }
    owner 0
    group 0
    mode '0644'
    action :create_if_missing
  end

  execute 'install lego binary' do
    command <<~CMD
      tar -xzf #{tarball_path} -C #{Chef::Config[:file_cache_path]} && \
      install -m 0555 #{Chef::Config[:file_cache_path]}/lego #{install_path}
    CMD
    not_if "#{install_path} --version | grep -F '#{lego_version_for_checksums}'"
  end
end
