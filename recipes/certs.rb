#
# Cookbook:: chatmail
# Recipe:: certs
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# You could use the debian package, but it is older and has fewer
# supported DNS providers.
#
# package 'chatmail'

# Install the correct version of lego with automatic download, checksum verification, and version checking
lego_binary node['lego']['release'] do
  install_path '/usr/bin/lego'
end

cookbook_file '/etc/lego/renew_hook.sh' do
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

template '/etc/systemd/system/lego-renewal.service' do
  source 'lego-renewal.service.erb'
  owner 0
  group 0
  mode '0644'
  variables(
    lego_email: lego_email,
    lego_domain: lego_domain,
    lego_path: lego_path,
    lego_dns_provider: lego_dns_provider,
    lego_dns_envs: lego_dns_envs
  )
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[lego-renewal]', :delayed
end

service 'lego-renewal' do
  action :enable
end

template '/etc/systemd/system/lego-renewal.timer' do
  source 'lego-renewal.timer.erb'
  owner 0
  group 0
  mode '0644'
  notifies :run, 'execute[systemctl daemon-reload]', :immediately
  notifies :restart, 'service[lego-renewal.timer]', :delayed
end

service 'lego-renewal.timer' do
  action [:enable, :start]
end

execute 'systemctl daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
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
