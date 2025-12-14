#
# Cookbook:: chatmail
# Recipe:: wwwfiles
#
# Copyright:: 2023, The Authors, All Rights Reserved.

platform_www = node['wwwdir'] + '/html'
bindir = node['bindir']
lowdown_path = bindir + '/lowdown'
qrencode_path = bindir + '/qrencode'

directory platform_www
directory "#{platform_www}/src"
directory "#{platform_www}/html"

%w(index info privacy).each do |f|
  template "#{platform_www}/src/#{f}.md" do
    owner 0
    group 0
    mode '0644'
    variables({ 'config' => node['chatmail'], 'pagename' => f })
    notifies :run, "execute[lowdown #{f}.md]", :immediately
  end

  execute "lowdown #{f}.md" do
    action :nothing
    command "#{lowdown_path} --html-no-skiphtml --html-no-escapehtml -o #{platform_www}/html/#{f}.html #{platform_www}/src/#{f}.md"
  end
end

%w(collage-info.png collage-privacy.png collage-top.png logo.svg main.css).each do |f|
  cookbook_file "#{platform_www}/html/#{f}" do
    owner 0
    group 0
    mode '0644'
  end
end

domain = node['chatmail']['domain']
qr_file = "#{platform_www}/html/qr-chatmail-invite-#{domain}.png"
execute 'qrencode' do
  command "#{qrencode_path} -lH -o #{qr_file} DCACCOUNT:https://#{domain}/new"
  not_if { ::File.exist?(qr_file) }
end

file "#{platform_www}/html/robots.txt" do
  owner 0
  group 0
  mode '0644'
  content <<~EOU
User-agent: *
Disallow: /
EOU
end
