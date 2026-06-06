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

  package_repo_base = "http://pkg.radiks.org/debian/#{debian_major}/#{deb_arch}"

  package_specs = package_map.map do |package_name, checksum_key|
    package_filename = "#{package_name}_#{version}_#{deb_arch}.deb"
    package_path = "#{Chef::Config[:file_cache_path]}/#{package_filename}"
    package_url = "#{package_repo_base}/#{package_filename}"
    package_checksum = node['dovecot']['checksums'][checksum_key][checksum_arch]

    if package_checksum.nil? || package_checksum == 'xxx'
      raise "Missing checksum for #{package_name} on #{checksum_arch} (Debian #{debian_major})"
    end

    {
      name: package_name,
      filename: package_filename,
      path: package_path,
      url: package_url,
      checksum: package_checksum,
    }
  end.sort_by { |spec| spec[:name] }

  installed_version_matches = lambda do |package_name|
    cmd = Mixlib::ShellOut.new("dpkg-query -W -f='${Version}' #{package_name}")
    cmd.run_command
    cmd.error!

    installed_version = cmd.stdout.to_s.strip
    !installed_version.empty? && installed_version.end_with?(version)
  rescue Mixlib::ShellOut::ShellCommandFailed
    false
  end

  marker_path = "#{Chef::Config[:file_cache_path]}/dovecot_#{deb_arch}_install.marker"
  marker_lines = [
    "version=#{version}",
    "debian_major=#{debian_major}",
    "deb_arch=#{deb_arch}",
    "checksum_arch=#{checksum_arch}",
    "repo_base=#{package_repo_base}",
  ]
  package_specs.each do |spec|
    marker_lines << "package=#{spec[:name]}|filename=#{spec[:filename]}|checksum=#{spec[:checksum]}|url=#{spec[:url]}"
  end
  marker_contents = "#{marker_lines.join("\n")}\n"

  marker_matches = begin
    ::File.exist?(marker_path) && ::File.read(marker_path) == marker_contents
  rescue
    false
  end

  versions_match = package_map.keys.all? { |package_name| installed_version_matches.call(package_name) }

  if versions_match && marker_matches
    Chef::Log.info("Correct dovecot package version (#{version}) already installed for Debian #{debian_major}/#{deb_arch}, skipping download/install")
    return
  end

  package_paths = package_specs.map { |spec| spec[:path] }

  package_specs.each do |spec|
    remote_file spec[:path] do
      source spec[:url]
      checksum spec[:checksum]
      owner 0
      group 0
      mode '0644'
      action :create
    end
  end

  apt_update 'update package cache for dovecot dependencies' do
    action :nothing
  end

  execute 'install custom dovecot packages with dependency resolution' do
    command "apt-get install -y #{package_paths.join(' ')}"
    environment({ 'DEBIAN_FRONTEND' => 'noninteractive' })
    not_if { package_map.keys.all? { |package_name| installed_version_matches.call(package_name) } && marker_matches }
    notifies :update, 'apt_update[update package cache for dovecot dependencies]', :before
  end

  file marker_path do
    content marker_contents
    owner 0
    group 0
    mode '0644'
    action :create
    only_if { package_map.keys.all? { |package_name| installed_version_matches.call(package_name) } }
  end
end
