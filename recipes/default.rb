#
# Cookbook:: chatmail
# Recipe:: default
#
# Copyright:: 2024, The Authors, All Rights Reserved.

include_recipe 'chatmail::journald'
include_recipe 'chatmail::certs'
include_recipe 'chatmail::wwwfiles'
include_recipe 'chatmail::postfix'
include_recipe 'chatmail::opendkim'
include_recipe 'chatmail::dovecot'
include_recipe 'chatmail::nginx'
include_recipe 'chatmail::mtail'
include_recipe 'chatmail::chatmaild'
