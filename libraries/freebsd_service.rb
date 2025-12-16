require 'chef/resource/service'
require 'chef/provider/service/init'

class Chef
  class Provider
    class Service
      class Freebsd < Chef::Provider::Service::Init
        def load_current_resource
          @current_resource = Chef::Resource::Service.new(new_resource.name)
          current_resource.service_name(new_resource.service_name)

          # Set default supports for FreeBSD rc.d scripts which universally support status and restart
          supports[:status]
          supports[:restart]

          @status_load_success = true
          determine_current_status! # Check running status

          determine_enabled_status! # Check enabled status
          current_resource
        end

        def start_service
          if new_resource.start_command
            super
          else
            shell_out!("/usr/sbin/service #{new_resource.service_name} start", default_env: false)
          end
        end

        def stop_service
          if new_resource.stop_command
            super
          else
            shell_out!("/usr/sbin/service #{new_resource.service_name} stop", default_env: false)
          end
        end

        def restart_service
          if new_resource.restart_command
            super
          else
            shell_out!("/usr/sbin/service #{new_resource.service_name} restart", default_env: false)
          end
        end

        def reload_service
          if new_resource.reload_command
            super
          elsif supports[:reload]
            shell_out!("/usr/sbin/service #{new_resource.service_name} reload", default_env: false)
          end
        end

        def enable_service
          # Use sysrc for enabling services on FreeBSD
          set_service_enable('YES') unless current_resource.enabled
        end

        def disable_service
          # Use sysrc for disabling services on FreeBSD
          set_service_enable('NO') if current_resource.enabled
        end

        protected

        def determine_current_status!
          # Use the FreeBSD service command to check status: /usr/sbin/service SERVICENAME status
          logger.trace("#{new_resource} running status check: /usr/sbin/service #{new_resource.service_name} status")
          begin
            result = shell_out("/usr/sbin/service #{new_resource.service_name} status", default_env: false)
            if result.exitstatus == 0
              current_resource.running true
              logger.trace("#{new_resource} is running")
            else
              current_resource.running false
              logger.trace("#{new_resource} is not running (exit code: #{result.exitstatus})")
            end
          rescue Mixlib::ShellOut::ShellCommandFailed, SystemCallError => e
            @status_load_success = false
            current_resource.running false
            logger.trace("#{new_resource} status check failed: #{e.message}")
          end
        end

        private

        def read_sysrc_variable(var_name)
          shell_out!("/usr/sbin/sysrc -e #{var_name}", returns: [0, 1], environment: { 'RC_CONFS' => rc_conf_files }).stdout.lines
        end

        def determine_enabled_status!
          var_name = service_enable_variable_name
          if var_name
            read_sysrc_variable(var_name).each do |line|
              case line
              when /^#{Regexp.escape(var_name)}="(\w+)"/
                enabled_state_found!
                if ::Regexp.last_match(1) =~ /^yes$/i
                  current_resource.enabled true
                elsif ::Regexp.last_match(1) =~ /^(no|none)$/i
                  current_resource.enabled false
                end
              end
            end
          end
          if current_resource.enabled.nil?
            current_resource.enabled false
          end
        end

        def set_service_enable(value)
          shell_out!("/usr/sbin/sysrc #{service_enable_variable_name}=#{value}", environment: { 'RC_CONFS' => rc_conf_files })
        end

        def rc_conf_files
          @rc_conf_files ||= shell_out!('/usr/sbin/sysrc -l').stdout.strip + ' ' + shell_out!("/usr/sbin/sysrc -L #{new_resource.service_name} || echo").stdout.strip
        end

        # The variable name used in /etc/rc.conf for enabling this service
        def service_enable_variable_name
          @service_enable_variable_name ||=
            begin
              if init_command
                # Try to parse rcvar output first, for cases like nfsd
                rcvar = shell_out!("#{init_command} rcvar").stdout[/(\w+_enable)=/, 1]
                if rcvar
                  rcvar
                else
                  # Look for name="foo" in the shell script @init_command. Use this for determining the variable name in /etc/rc.conf
                  # corresponding to this service
                  # For example: to enable the service mysql-server with the init command /usr/local/etc/rc.d/mysql-server, you need
                  # to set mysql_enable="YES" in /etc/rc.conf$
                  Chef::Log.debug("name_enable not found in #{init_command} rcvar, falling back to parsing")
                  ::File.open(init_command) do |rcscript|
                    rcscript.each_line do |line|
                      if line =~ /^name="?(\w+)"?/
                        return ::Regexp.last_match(1) + '_enable'
                      end
                    end
                  end
                end
              else
                # for why-run mode when the rcd_script is not there yet
                new_resource.service_name + '_enable'
              end
            end
        end

        def enabled_state_found!
          @enabled_state_found = true
        end
      end
    end
  end
end
