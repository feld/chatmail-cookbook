resource_name :freebsd_sysrc
provides :freebsd_sysrc

property :key,          String, name_property: true
property :value,        String
property :rc_conf_file, String, desired_state: false, default: '/etc/rc.conf'


action :create do
  # Check if a change is needed using sysrc -c with the full value we want to set
  check_command = "sysrc -c"
  check_command += " -f #{new_resource.rc_conf_file}" if new_resource.rc_conf_file != '/etc/rc.conf'
  check_command += " #{new_resource.key}=\"#{new_resource.value}\""

  execute "set #{new_resource.key} in #{new_resource.rc_conf_file}" do
    command "sysrc#{' -f ' + new_resource.rc_conf_file if new_resource.rc_conf_file != '/etc/rc.conf'} #{new_resource.key}=\"#{new_resource.value}\""
    # Run only if sysrc -c indicates a change is needed (exit code 1)
    only_if { shell_out(check_command, returns: [0, 1]).exitstatus == 1 }
  end
end

action :delete do
  # Check if the key exists before attempting to delete it
  check_command = "sysrc -c"
  check_command += " -f #{new_resource.rc_conf_file}" if new_resource.rc_conf_file != '/etc/rc.conf'
  check_command += " #{new_resource.key}"

  execute "delete #{new_resource.key} from #{new_resource.rc_conf_file}" do
    cmd = "sysrc -x #{new_resource.key}"
    cmd += " -f #{new_resource.rc_conf_file}" if new_resource.rc_conf_file != '/etc/rc.conf'
    command cmd
    # Run only if the key exists (sysrc -c succeeds with exit code 0 when key exists)
    only_if { shell_out(check_command, returns: [0, 1]).exitstatus == 0 }
  end
end
