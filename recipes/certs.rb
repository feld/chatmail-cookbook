#
# Cookbook:: chatmail
# Recipe:: certs
#
# Copyright:: 2023, The Authors, All Rights Reserved.

platform_etc = node['etcdir']
lego_bin_path = node['lego']['bin']
lego_path = node['lego']['path']
certdir = node['chatmail']['certificates_dir']

directory lego_path do
  owner 0
  group 0
  mode '0755'
  recursive true
end

directory certdir do
  owner 0
  group 0
  mode '0755'
  recursive true
end

cookbook_file "#{platform_etc}/lego/renew_hook.sh" do
  owner 0
  group 0
  mode '0555'
end

lego_email = node['lego']['email']
lego_domain = node['chatmail']['domain']
lego_dns_provider = node['lego']['provider']
lego_dns_envs = node['lego']['envs']
lego_server = node['lego']['server']

lego_issuance_command = "#{lego_bin_path} run -a -s #{lego_server} -d #{lego_domain} -d www.#{lego_domain} -d mta-sts.#{lego_domain} -m #{lego_email} --path #{lego_path} --dns #{lego_dns_provider}"

lego_deploy_hook = "#{platform_etc}/lego/renew_hook.sh"

if platform_family?('freebsd')
  cron_d 'lego_renewal' do
    minute '30'
    hour '2'
    command "#{lego_issuance_command} --deploy-hook=#{lego_deploy_hook}"
    user 'root'
    environment lego_dns_envs
  end
else
  template '/etc/systemd/system/lego-renewal.service' do
    source 'lego-renewal.service.erb'
    owner 0
    group 0
    mode '0644'
    variables(
      lego_dns_envs: lego_dns_envs,
      lego_issuance_command: lego_issuance_command,
      lego_deploy_hook: lego_deploy_hook
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
end

execute 'Lego v5.0 Account Migration' do
  command "printf 'Y\\n' | #{lego_bin_path} migrate --path #{lego_path}"
  live_stream true
  only_if "#{lego_bin_path} --version | grep -Eq '(^| )v?5\\.'"
  only_if { ::Dir.glob("#{lego_path}/accounts/*/#{lego_email}/keys").any? }
end

execute 'issue_cert' do
  command lego_issuance_command
  environment(lego_dns_envs)
  live_stream true
  not_if { ::File.exist?(certdir + '/' + lego_domain + '.key') }
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
