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
  checksum_cache_file = "#{Chef::Config[:file_cache_path]}/#{tarball_name}.sha256"
  binary_checksum_cache_file = "#{checksum_cache_file}.binary"

  cached_binary_checksum = read_checksum_file(binary_checksum_cache_file)
  if ::File.executable?(install_path) && !cached_binary_checksum.nil? && checksum_match?(install_path, cached_binary_checksum)
    Chef::Log.info("Correct lego binary already installed at #{install_path}, skipping download/install")
    return
  end

  remote_file checksums_file do
    source checksums_url
    owner 0
    group 0
    mode '0644'
    action :create
  end

  ruby_block "cache checksum for #{tarball_name}" do
    block do
      checksum = checksum_from_release_file(checksums_file, tarball_name)
      ::File.write(checksum_cache_file, "#{checksum}\n")
    end
    action :run
    not_if do
      cached_checksum = read_checksum_file(checksum_cache_file)
      next false if cached_checksum.nil?

      cached_checksum.casecmp?(checksum_from_release_file(checksums_file, tarball_name))
    end
  end

  remote_file tarball_path do
    source download_url
    checksum lazy { read_checksum_file(checksum_cache_file) }
    owner 0
    group 0
    mode '0644'
    action :create
  end

  ruby_block "cache lego binary checksum for #{tarball_name}" do
    block do
      require 'digest'
      require 'zlib'
      require 'rubygems/package'

      binary_checksum = nil

      Zlib::GzipReader.open(tarball_path) do |gzip_stream|
        Gem::Package::TarReader.new(gzip_stream) do |tar|
          tar.each do |entry|
            next unless entry.file? && entry.full_name == 'lego'

            binary_checksum = Digest::SHA256.hexdigest(entry.read)
            break
          end
        end
      end

      raise "Could not find lego binary in #{tarball_path}" if binary_checksum.nil?

      ::File.write(binary_checksum_cache_file, "#{binary_checksum}\n")
    end
    action :run
    not_if do
      expected_binary_checksum = read_checksum_file(binary_checksum_cache_file)
      next false if expected_binary_checksum.nil?

      ::File.executable?(install_path) && checksum_match?(install_path, expected_binary_checksum)
    end
  end

  ruby_block 'install lego binary' do
    block do
      require 'zlib'
      require 'rubygems/package'

      extracted_binary_path = "#{Chef::Config[:file_cache_path]}/lego-#{lego_version}-#{arch_name}"
      extracted = false

      Zlib::GzipReader.open(tarball_path) do |gzip_stream|
        Gem::Package::TarReader.new(gzip_stream) do |tar|
          tar.each do |entry|
            next unless entry.file? && entry.full_name == 'lego'

            ::File.open(extracted_binary_path, 'wb') { |f| f.write(entry.read) }
            extracted = true
            break
          end
        end
      end

      raise "Could not find lego binary in #{tarball_path}" unless extracted

      install_binary(extracted_binary_path, install_path)
    end
    not_if do
      expected_binary_checksum = read_checksum_file(binary_checksum_cache_file)
      ::File.executable?(install_path) &&
        !expected_binary_checksum.nil? &&
        checksum_match?(install_path, expected_binary_checksum)
    end
  end
end
