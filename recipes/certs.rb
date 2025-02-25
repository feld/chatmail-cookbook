#
# Cookbook:: chatmail
# Recipe:: certs
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# You could use the debian package, but it is older and has fewer
# supported DNS providers.
#
# package 'chatmail'

cookbook_file '/usr/bin/lego' do
  owner 0
  group 0
  mode '0555'
end

certdir = node['chatmail']['certificates_dir']

directory certdir do
  owner 0
  group 0
  mode '0755'
  recursive true
end

lego_email = node['lego']['email']
lego_domain = node['chatmail']['domain']
lego_path = node['lego']['path']
lego_dns_provider = node['lego']['provider']
lego_dns_envs = node['lego']['envs']

systemd_unit 'lego-renewal.service' do
  action [:create, :enable]
  verify true
  content <<~EOU
  [Unit]
  Description=LetsEncrypt certificate renewal

  [Service]
  Type=oneshot
  #{lego_dns_envs.map { |key, value| "Environment=\"#{key}=#{value}\"" }.join("\n")}
  ExecStart=/usr/bin/lego -a -d #{lego_domain} -d www.#{lego_domain} -d mta-sts.#{lego_domain} -m #{lego_email} --path #{lego_path} --dns #{lego_dns_provider} renew

  [Install]
  WantedBy=multi-user.target
  EOU
end

systemd_unit 'lego-renewal.timer' do
  action [:create, :enable, :start]
  verify true
  content(
    Unit: {
      Description: 'Daily LetsEncrypt certificate renewal',
    },
    Timer: {
      OnCalendar: 'daily',
      Unit: 'lego-renewal.service',
    },
    Install: {
      WantedBy: 'timers.target',
    }
  )
end

execute 'issue_cert' do
  command "/usr/bin/lego -a -d #{lego_domain} -d www.#{lego_domain} -d mta-sts.#{lego_domain} -m #{lego_email} --path #{lego_path} --dns #{lego_dns_provider} run"
  environment(lego_dns_envs)
  not_if { ::File.exist?(certdir + '/' + lego_domain + '.pem.key') }
end

file certdir + '/' + lego_domain + '.key' do
  owner 0
  group 0
  mode '0440'
  only_if { ::File.exist?(certdir + '/' + lego_domain + '.key') }
end

link certdir + '/' + lego_domain + '.pem.key' do
  to certdir + '/' + lego_domain + '.key'
  only_if { ::File.exist?(certdir + '/' + lego_domain + '.key') }
end

link certdir + '/' + lego_domain + '.pem' do
  to certdir + '/' + lego_domain + '.crt'
  only_if { ::File.exist?(certdir + '/' + lego_domain + '.crt') }
end
