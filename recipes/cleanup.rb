#
# Cookbook:: chatmail
# Recipe:: cleanup
#
# Copyright:: 2023, The Authors, All Rights Reserved.

%w(postfix-mta-sts-resolver.service).each do |x|
  service x do
    action [:stop, :disable]
  end
end

%w(postfix-mta-sts-resolver).each do |x|
  package x do
    action :purge
  end
end

%w(/etc/mta-sts-daemon.yml).each do |x|
  file x do
    action :delete
  end
end

%w(/usr/local/lib/postfix-mta-sts-resolver).each do |x|
  directory x do
    action :delete
    recursive true
  end
end
