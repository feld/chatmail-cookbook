resource_name :freebsd_sysrc
provides :freebsd_sysrc

property :key,          String, name_property: true
property :value,        String
property :rc_conf_file, String, desired_state: false, default: '/etc/rc.conf'

load_current_value do
  # Use sysrc to check the current value
  command = "sysrc -c"
  command += " -f #{rc_conf_file}" if rc_conf_file != '/etc/rc.conf'
  command += " #{key}"

  result = shell_out(command, returns: [0, 1])
  if result.exitstatus == 0
    # sysrc -c outputs "key: value", so we extract the value
    output = result.stdout.strip
    if output =~ /^#{key}:\s*(.*)$/
      value $1
    end
  end
end

action :create do
  converge_if_changed do
    command = "sysrc"
    command += " -f #{new_resource.rc_conf_file}" if new_resource.rc_conf_file != '/etc/rc.conf'
    command += " #{new_resource.key}=\"#{new_resource.value}\""

    execute "set #{new_resource.key} in #{new_resource.rc_conf_file}" do
      command command
      not_if { current_resource && current_resource.value == new_resource.value }
    end
  end
end

action :delete do
  execute "delete #{new_resource.key} from #{new_resource.rc_conf_file}" do
    cmd = "sysrc -x #{new_resource.key}"
    cmd += " -f #{new_resource.rc_conf_file}" if new_resource.rc_conf_file != '/etc/rc.conf'
    command cmd
    only_if { current_resource && !current_resource.value.nil? }
  end
end
