# frozen_string_literal: true

provides :freebsd_sysctl, platform_family: 'freebsd'

unified_mode true

description 'Use the **freebsd_sysctl** resource to manage FreeBSD sysctl parameters.'

property :variable, String,
         name_property: true,
         description: 'The name of the sysctl variable to manage.'

property :value, [String, Integer, Float, TrueClass, FalseClass],
         description: 'The value to set for the sysctl variable.'

action :set do
  # Set the sysctl value at runtime if value is provided
  unless new_resource.value.nil?
    current_value = get_current_value
    if current_value != new_resource.value.to_s
      converge_by("set #{new_resource.variable}=#{new_resource.value}") do
        shell_out!('sysctl', "#{new_resource.variable}=#{new_resource.value}")
        Chef::Log.info("Set sysctl #{new_resource.variable} to #{new_resource.value}")
      end
    end
  end

  # Manage the sysctl.conf entry
  # Use the line cookbook to add the sysctl variable to sysctl.conf
  replace_or_add "add #{new_resource.variable} to sysctl.conf" do
    path '/etc/sysctl.conf.local'
    line "#{new_resource.variable}=#{new_resource.value}"
    pattern "^#{Regexp.escape(new_resource.variable)}="
  end
end

action :remove do
  # Remove the sysctl setting from runtime
  current_value = get_current_value
  if current_value
    converge_by("remove #{new_resource.variable} from runtime") do
      # Get the default value and reset it
      default_value = get_default_value
      if default_value
        shell_out!('sysctl', "#{new_resource.variable}=#{default_value}")
        Chef::Log.info("Reset sysctl #{new_resource.variable} to default value: #{default_value}")
      else
        # If we can't determine the default, try to reset using sysctl -w with the reset mechanism
        # For some parameters, we might need to use sysctl -X to get the reset value
        Chef::Log.warn("Could not determine default value for #{new_resource.variable}, manual reset may be needed")
      end
    end
  end

  # Remove the sysctl.conf entry
  delete_lines "remove #{new_resource.variable} from sysctl.conf" do
    path '/etc/sysctl.conf.local'
    pattern "^#{Regexp.escape(new_resource.variable)}="
  end
end

action_class do
  def get_current_value
    # Get current value using sysctl -n variable
    cmd = shell_out('sysctl', '-n', new_resource.variable, returns: [0, 1])
    cmd.stdout.strip if cmd.exitstatus.zero?
  rescue StandardError => e
    Chef::Log.warn("Error getting current value of #{new_resource.variable}: #{e.message}")
    nil
  end

  def get_default_value
    # Get default value using sysctl -d variable (description format) and parsing
    cmd = shell_out('sysctl', '-d', new_resource.variable, returns: [0, 1])
    if cmd.exitstatus.zero?
      # The output format is typically "variable: default_value description" or similar
      output = cmd.stdout.strip
      # Try to extract the default value from the output
      if (match = output.match(/#{Regexp.escape(new_resource.variable)}:\s*(.+?)\s*(?:#.*)?$/))
        return match[1].strip
      elsif (match = output.match(/:\s*(.+)$/))
        # Fallback: take everything after the last colon and space
        return match[1].strip
      end
    end

    # If -d doesn't work, try alternative methods
    # Some sysctls can be reset by getting their current value from the kernel directly
    nil
  rescue StandardError => e
    Chef::Log.warn("Error getting default value of #{new_resource.variable}: #{e.message}")
    nil
  end
end
