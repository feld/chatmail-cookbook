#
# Cookbook:: chatmail
# Recipe:: version_crumb
#
# Copyright:: 2023, The Authors, All Rights Reserved.

# helpful little bugger to let you know which cookbook
# version was deployed

cookbook_version = node['cookbooks']['chatmail']['version']

file '/etc/chatmail-release' do
   sensitive true
   content <<~EOU
#{cookbook_version}
EOU
end
