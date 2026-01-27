#
# Cookbook:: chatmail
# Recipe:: zone
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# Determine platform-specific paths
if platform?('freebsd')
  platform_etc = '/usr/local/etc'
  platform_www = '/usr/local/www'
else
  platform_etc = '/etc'
  platform_www = '/var/www'
end

ruby_block 'generate dkim txt value and sts_id' do
  block do
    selector = node['chatmail']['dkim_selector']
    dkim_pubkey = `openssl rsa -in #{platform_etc}/dkimkeys/#{selector}.private -pubout 2>/dev/null | awk '/-/{next}{printf("%s",$0)}'`
    dkim_txt_raw = "v=DKIM1;k=rsa;p=#{dkim_pubkey};s=email;t=s"
    dkim_txt_value = dkim_txt_raw.scan(/.{1,255}/).map { |chunk| "\"#{chunk}\"" }.join(' ')
    node.override['dkim_txt_value'] = dkim_txt_value
    node.override['sts_id'] = File.stat("#{platform_www}/html/.well-known/mta-sts.txt").mtime.to_i
  end
end

require 'json'

begin
  account_file = node['lego']['path'] + '/accounts/acme-v02.api.letsencrypt.org/' + node['lego']['email'] + '/' + 'account.json'

  if File.exist?(account_file)
    account_data = JSON.parse(File.read(account_file))
    account_uri = account_data.dig('registration', 'uri')
  else
    'error_reading_uri'
  end
end

template('/tmp/chatmail.zone') do
  source 'zone.erb'
  mode '0644'
  variables(lazy do
    { 'config' => node['chatmail'], 'sts_id' => node['sts_id'], 'dkim_txt' => node['dkim_txt_value'], 'account_uri' => account_uri }
  end
           )
  sensitive true
end

ruby_block 'print zone' do
  block do
    result = File.read('/tmp/chatmail.zone')
    text = <<~EOF

    #{result}
    EOF
    Chef::Log.warn(text)
  end
end
