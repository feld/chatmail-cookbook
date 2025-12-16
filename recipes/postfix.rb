#
# Cookbook:: chatmail
# Recipe:: postfix
#
# Copyright:: 2023, The Authors, All Rights Reserved.

platform_etc = node['etcdir']
spool_dir = '/var/spool/postfix'
opendkim_user = node['opendkim']['user']
opendkim_group = node['opendkim']['group']
opendkim_service = node['opendkim']['service']

cookbook_file "#{platform_etc}/postfix/login_map" do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[postfix]', :delayed
end

cookbook_file "#{platform_etc}/postfix/submission_header_cleanup" do
  owner 0
  group 0
  mode '0644'
  notifies :restart, 'service[postfix]', :delayed
end

# FreeBSD doesn't want to work verifying using the
# /etc/ssl/certs dir for some reason. It errors like
# postfix/smtp[53908]: certificate verification failed for e2ee.wang[139.84.233.161]:25: untrusted issuer /C=US/O=Internet Security Research Group/CN=ISRG Root X1
# even though curl etc are ok with it

case node['platform_family']
  when 'freebsd'
   smtp_tls_trust_source = 'smtp_tls_CAfile=/etc/ssl/cert.pem'
else
   smtp_tls_trust_source = 'smtp_tls_CApath=/etc/ssl/certs'
end

template "#{platform_etc}/postfix/main.cf" do
  owner 0
  group 0
  mode '0644'
  variables(
    'config' => node['chatmail'],
    'postfix_config_dir' => "#{platform_etc}/postfix",
    'smtp_tls_trust_source' => smtp_tls_trust_source
  )
  notifies :restart, 'service[postfix]', :delayed
end

template "#{platform_etc}/postfix/master.cf" do
  owner 0
  group 0
  mode '0644'
  variables(
    'config' => node['chatmail'],
    'postfix_config_dir' => "#{platform_etc}/postfix"
  )
  notifies :restart, 'service[postfix]', :delayed
end

group opendkim_group do
  append true
  members ['postfix']
  action :modify
  notifies :restart, 'service[postfix]', :delayed
end

directory "#{spool_dir}/opendkim" do
  owner opendkim_user
  group opendkim_group
  mode '0750'
  notifies :restart, "service[#{opendkim_service}]", :delayed
end

service 'postfix' do
  action [:enable, :start]
end

service opendkim_service do
  action :nothing
end

if platform_family?('freebsd')
  remote_file '/usr/local/etc/mail/mailer.conf' do
    source 'file:///usr/local/share/postfix/mailer.conf.postfix'
    owner 0
    group 0
    mode '0644'
  end

  file '/etc/rc.conf.d/sendmail' do
    owner 0
    group 0
    mode '0644'
    content 'sendmail_enable="NONE"'
  end
end

execute 'newaliases' do
  not_if { ::File.exist?('/etc/aliases.db') }
end
