#
# Cookbook:: chatmail
# Recipe:: default
#
# Copyright:: 2024, The Authors, All Rights Reserved.

include_recipe 'chatmail::vmail_user'
include_recipe 'chatmail::packages'
include_recipe 'chatmail::environment'
include_recipe 'chatmail::unbound'
include_recipe 'chatmail::journald'
include_recipe 'chatmail::logrotate'
include_recipe 'chatmail::certs'
include_recipe 'chatmail::wwwfiles'
include_recipe 'chatmail::opendkim'
include_recipe 'chatmail::dovecot'
include_recipe 'chatmail::postfix'
include_recipe 'chatmail::iroh'
include_recipe 'chatmail::turn'
include_recipe 'chatmail::nginx'
include_recipe 'chatmail::mtail'
include_recipe 'chatmail::chatmaild'
include_recipe 'chatmail::cron'
include_recipe 'chatmail::syslogd'
include_recipe 'chatmail::systemd'
include_recipe 'chatmail::sysctl'
include_recipe 'chatmail::cleanup'
include_recipe 'chatmail::zone'
