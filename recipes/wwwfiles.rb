#
# Cookbook:: chatmail
# Recipe:: wwwfiles
#
# Copyright:: 2023, The Authors, All Rights Reserved.

package %w(lowdown qrencode)

directory '/var/www/src'

%w(index info privacy).each do |f|
  template "/var/www/src/#{f}.md" do
    owner 0
    group 0
    mode '0644'
    variables({ 'config' => node['chatmail'], 'pagename' => f })
    notifies :run, "execute[lowdown #{f}.md]", :immediately
  end

  execute "lowdown #{f}.md" do
    command "/usr/bin/lowdown --html-no-skiphtml --html-no-escapehtml -o /var/www/html/#{f}.html /var/www/src/#{f}.md"
    action :nothing
  end
end

%w(collage-info.png collage-privacy.png collage-top.png logo.svg main.css).each do |f|
  cookbook_file "/var/www/html/#{f}" do
    owner 0
    group 0
    mode '0644'
  end
end

domain = node['chatmail']['domain']
qr_file = "/var/www/html/qr-chatmail-invite-#{domain}.png"
execute 'qrencode' do
  command "qrencode -lH -o #{qr_file} DCACCOUNT:https://#{domain}/new"
    not_if { ::File.exist?(qr_file) }
end
