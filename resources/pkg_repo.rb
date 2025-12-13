# frozen_string_literal: true

#
# Cookbook:: chatmail
# Resource:: pkg_repo
#

resource_name :pkg_repository
provides :pkg_repository
unified_mode true

property :repo_name, String, name_property: true
property :cookbook, String, default: 'chatmail'
property :enabled, [true, false], default: true
property :mirror_type, String, default: 'http'
property :url, String, required: true
property :signature_type, String
property :pubkey_source, String
property :pubkey_cookbook, String
property :mode, [Integer, String], default: 0o0755
property :priority, Integer, default: 0

def after_created
  raise 'pkg_repo requires FreeBSD, the one true OS.' unless platform_family?('freebsd')
end

action :create do
  create_template(:create)
end

action :create_if_missing do
  create_template(:create_if_missing)
end

action :delete do
  # cleanup the legacy repo, if present
  file 'pkg repo file' do
    path "/usr/local/etc/pkg/repos/#{new_resource.repo_name}.conf"
    action :delete
  end

  file "/usr/local/etc/pkg/repos/#{sanitized_name}.conf" do
    action :delete
  end
end

action_class do
  def sanitized_name
    new_resource.repo_name.tr('.', '-')
  end

  def create_template(create_action)
    # ensure pkg repos directory exists
    %w(pubkeys repos).each do |dir|
      directory ::File.join('/usr/local/etc/pkg', dir) do
        mode '755'
        action :create
        owner node['root_user']
        group node['root_group']
        recursive true
      end
    end

    if new_resource.pubkey_source
      pubkey = ::File.join('/usr/local/etc/pkg/pubkeys', "#{sanitized_name}.pub")
      cookbook_file pubkey do
        source new_resource.pubkey_source
        cookbook new_resource.pubkey_cookbook
        sensitive true
        mode '444'
        owner node['root_user']
        group node['root_group']
      end
    end

    # cleanup the legacy entry, if present
    file "#{new_resource.repo_name} pkg repo config" do
      path "/usr/local/etc/pkg/repos/#{new_resource.repo_name}.conf"
      action :delete
      only_if { new_resource.repo_name != sanitized_name }
    end

    template "/usr/local/etc/pkg/repos/#{sanitized_name}.conf" do
      cookbook new_resource.cookbook
      source 'pkg_repo.conf.erb'
      mode new_resource.mode
      variables(
        name: sanitized_name,
        signature_type: new_resource.signature_type,
        pubkey: pubkey,
        enabled: new_resource.enabled,
        mirror_type: new_resource.mirror_type,
        url: new_resource.url,
        priority: new_resource.priority
      )
      action create_action
      notifies :run, "execute[update pkg cache for #{new_resource.repo_name}]", :immediately if new_resource.enabled
    end

    execute "update pkg cache for #{new_resource.repo_name}" do
      command "pkg update -r #{new_resource.repo_name}"
      action :nothing
    end
  end
end
