# frozen_string_literal: true

resource_name :debian_dovecot_packages
provides :debian_dovecot_packages, platform: 'debian'
unified_mode true

action :install do
  unless platform?('debian')
    raise 'debian_dovecot_packages is only supported on Debian'
  end

  debian_major = node['platform_version'].to_i
  chef_arch = node['kernel']['machine']

  arch_map = {
    'x86_64' => 'amd64',
    'aarch64' => 'arm64',
  }

  checksum_arch_map = {
    'x86_64' => 'x86_64',
    'aarch64' => 'aarch64',
  }

  deb_arch = arch_map[chef_arch]
  checksum_arch = checksum_arch_map[chef_arch]

  raise "Unsupported architecture for Debian Dovecot packages: #{chef_arch}" if deb_arch.nil? || checksum_arch.nil?

  version = node['dovecot']['archive_version']

  package_map = {
    'dovecot-core' => 'core',
    'dovecot-imapd' => 'imapd',
    'dovecot-lmtpd' => 'lmtpd',
  }

  package_paths = []

  package_map.each do |package_name, checksum_key|
    package_filename = "#{package_name}_#{version}_#{deb_arch}.deb"
    package_path = "#{Chef::Config[:file_cache_path]}/#{package_filename}"
    package_url = "http://pkg.radiks.org/debian/#{debian_major}/#{deb_arch}/#{package_filename}"
    package_checksum = node['dovecot']['checksums'][checksum_key][checksum_arch]

    if package_checksum.nil? || package_checksum == 'xxx'
      raise "Missing checksum for #{package_name} on #{checksum_arch} (Debian #{debian_major})"
    end

    remote_file package_path do
      source package_url
      checksum package_checksum
      owner 0
      group 0
      mode '0644'
      action :create_if_missing
    end

    package_paths << package_path
  end

  apt_update 'update package cache for dovecot dependencies' do
    action :nothing
  end

  execute 'install custom dovecot packages with dependency resolution' do
    command "apt-get install -y #{package_paths.join(' ')}"
    environment({ 'DEBIAN_FRONTEND' => 'noninteractive' })
    not_if <<~EOH
      dpkg-query -W -f='${Version}' dovecot-core 2>/dev/null | grep -E '#{Regexp.escape(version)}$' && \
      dpkg-query -W -f='${Version}' dovecot-imapd 2>/dev/null | grep -E '#{Regexp.escape(version)}$' && \
      dpkg-query -W -f='${Version}' dovecot-lmtpd 2>/dev/null | grep -E '#{Regexp.escape(version)}$'
    EOH
    notifies :update, 'apt_update[update package cache for dovecot dependencies]', :before
  end
end
