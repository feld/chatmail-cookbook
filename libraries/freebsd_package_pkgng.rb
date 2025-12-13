require 'chef/provider/package/freebsd/base'
require 'chef/resource/package'

# Extend Chef's built-in Package resource to add FreeBSD-specific properties
class Chef::Resource::Package
  property :vital, [TrueClass, FalseClass, nil],
    description: 'Whether the package should be marked as vital (critical to system operation). FreeBSD only.',
    default: nil

  property :repository, String,
    description: 'The name of the repository to install the package from. FreeBSD only.'
end

class Chef
  class Provider
    class Package
      module Freebsd
        class Pkgng < Base
          # Override action_install to handle repository switching and vital flag
          def action_install
            # Check if repository needs to be switched
            if new_resource.repository && current_installed_version && repository_mismatch?(new_resource.package_name)
              converge_by("switch package #{new_resource.package_name} to repository #{new_resource.repository}") do
                logger.info("#{new_resource} package #{new_resource.package_name} already installed but from different repository (#{current_repository(new_resource.package_name)}), switching to #{new_resource.repository}")
                install_from_repository
              end
            elsif current_resource.version.nil? || (candidate_version && candidate_version != current_resource.version)
              converge_by("install package #{new_resource.package_name}") do
                install_from_repository
              end
            else
              logger.trace("#{new_resource} is already installed - nothing to do")
              # Call super to ensure proper state management in why-run mode
              super
            end

            # Handle vital flag after install completes (or if already installed)
            handle_vital_flag_for_package
          end

          # Override action_upgrade to handle repository switching and vital flag
          def action_upgrade
            # Check if repository needs to be switched
            if new_resource.repository && current_installed_version && repository_mismatch?(new_resource.package_name)
              converge_by("switch package #{new_resource.package_name} to repository #{new_resource.repository} and upgrade") do
                logger.info("#{new_resource} package #{new_resource.package_name} already installed but from different repository (#{current_repository(new_resource.package_name)}), switching to #{new_resource.repository}")
                install_from_repository
              end
            else
              super
            end

            # Handle vital flag after upgrade completes
            handle_vital_flag_for_package
          end

          private

          def repository_mismatch?(name)
            current_repo = current_repository(name)
            !current_repo.nil? && new_resource.repository != current_repo
          end

          def install_from_repository
            # Call install_package with the current version to trigger repository switch
            if current_installed_version
              install_package(new_resource.package_name, current_installed_version)
            else
              install_package(new_resource.package_name, nil)
            end
          end

          def install_package(name, version)
            if current_resource.version
              # Check if repository needs to be switched
              current_repo = current_repository(name)
              if new_resource.repository && current_repo && new_resource.repository != current_repo
                logger.info("#{new_resource} package #{name} already installed but from different repository (#{current_repo}), switching to #{new_resource.repository}")
                repo_option = ['-r', new_resource.repository]
                if version
                  shell_out!('pkg', 'install', '-y', '-f', *repo_option, options, "#{name}-#{version}", env: { 'LC_ALL' => nil }, returns: [0, 78])
                else
                  shell_out!('pkg', 'install', '-y', '-f', *repo_option, options, name, env: { 'LC_ALL' => nil }, returns: [0, 78])
                end
              else
                logger.trace("#{new_resource} package #{name} already installed#{current_repo ? ' from correct repository' : ', no repository switching needed'}, skipping install")
              end
            else
              case new_resource.source
              when %r{^(http|ftp|/)}
                logger.trace("#{new_resource} installing from: #{new_resource.source}")
                shell_out!('pkg', 'add', options, new_resource.source, env: { 'LC_ALL' => nil }, returns: [0, 78])
              else
                # Check if repository is explicitly set in resource or in options
                if new_resource.repository
                  repo_option = ['-r', new_resource.repository]
                  logger.trace("#{new_resource} installing package #{name}#{version ? ' version ' + version : ''} from repository #{new_resource.repository}")
                  if version
                    shell_out!('pkg', 'install', '-y', *repo_option, options, "#{name}-#{version}", env: { 'LC_ALL' => nil }, returns: [0, 78])
                  else
                    shell_out!('pkg', 'install', '-y', *repo_option, options, name, env: { 'LC_ALL' => nil }, returns: [0, 78])
                  end
                elsif version
                  # Use options which may contain repository flag from options
                  logger.trace("#{new_resource} installing package #{name} version #{version}")
                  shell_out!('pkg', 'install', '-y', options, "#{name}-#{version}", env: { 'LC_ALL' => nil }, returns: [0, 78])
                else
                  logger.trace("#{new_resource} installing package #{name}")
                  shell_out!('pkg', 'install', '-y', options, name, env: { 'LC_ALL' => nil }, returns: [0, 78])
                end
              end
            end
          end

          def upgrade_package(name, version)
            if current_resource.version
              # Check if repository needs to be switched
              current_repo = current_repository(name)
              if new_resource.repository && current_repo && new_resource.repository != current_repo
                logger.info("#{new_resource} package #{name} already installed but from different repository (#{current_repo}), switching to #{new_resource.repository}")
                repo_option = ['-r', new_resource.repository]
                if version
                  shell_out!('pkg', 'install', '-y', '-f', *repo_option, options, "#{name}-#{version}", env: { 'LC_ALL' => nil }, returns: [0, 78])
                else
                  shell_out!('pkg', 'install', '-y', '-f', *repo_option, options, name, env: { 'LC_ALL' => nil }, returns: [0, 78])
                end
              elsif new_resource.repository
                # Upgrade specific package
                repo_option = ['-r', new_resource.repository]
                logger.trace("#{new_resource} upgrading package #{name}#{version ? ' to version ' + version : ''} from repository #{new_resource.repository}")
                if version
                  shell_out!('pkg', 'install', '-y', *repo_option, options, "#{name}-#{version}", env: { 'LC_ALL' => nil }, returns: [0, 78])
                else
                  shell_out!('pkg', 'upgrade', '-y', *repo_option, options, name, env: { 'LC_ALL' => nil }, returns: [0, 78])
                end
              elsif version
                # Use options which may contain repository flag from options
                logger.trace("#{new_resource} upgrading package #{name} to version #{version}")
                shell_out!('pkg', 'install', '-y', options, "#{name}-#{version}", env: { 'LC_ALL' => nil }, returns: [0, 78])
              else
                logger.trace("#{new_resource} upgrading package #{name}")
                shell_out!('pkg', 'upgrade', '-y', options, name, env: { 'LC_ALL' => nil }, returns: [0, 78])
              end
            else
              # Install if not currently installed
              logger.trace("#{new_resource} package not installed, installing #{name}")
              install_package(name, version)
            end
          end

          def remove_package(name, version)
            logger.trace("#{new_resource} removing package #{name}#{version ? '-' + version : ''}")
            options_dup = options && options.map { |str| str.sub(repo_regex, '') }.reject!(&:empty?)
            shell_out!('pkg', 'delete', '-y', options_dup, "#{name}#{version ? '-' + version : ''}", env: nil, returns: [0, 78])
          end

          def lock_package(name, _version)
            logger.trace("#{new_resource} locking package #{name}")
            shell_out!('pkg', 'lock', '-y', name, env: { 'LC_ALL' => nil }, returns: [0, 78])
          end

          def unlock_package(name, _version)
            logger.trace("#{new_resource} unlocking package #{name}")
            shell_out!('pkg', 'unlock', '-y', name, env: { 'LC_ALL' => nil }, returns: [0, 78])
          end

          def current_installed_version
            # pkgng up to version 1.15.99.7 returns 70 for pkg not found,
            # later versions return 1
            pkg_info = shell_out!('pkg', 'info', new_resource.package_name, env: nil, returns: [0, 1, 70])
            version_match = pkg_info.stdout[/^Version +: (.+)$/, 1]
            logger.trace("#{new_resource} current installed version is #{version_match}") if version_match
            version_match
          end

          def current_repository(name = nil)
            package_name = name || new_resource.package_name
            # Check if the package is installed first
            pkg_check = shell_out('pkg', 'info', package_name, env: nil, returns: [0, 1, 70])
            return unless pkg_check.exitstatus == 0

            # Get the repository tag for the installed package
            pkg_query = shell_out!('pkg', 'query', '%R', package_name, env: nil, returns: [0, 1])
            if pkg_query.exitstatus == 0
              repository_result = pkg_query.stdout.strip
              logger.trace("#{new_resource} current installed repository for #{package_name} is #{repository_result}")
              repository_result
            else
              # If query fails, return nil
              logger.trace("#{new_resource} could not determine repository for #{package_name}")
              nil
            end
          rescue => e
            logger.trace("#{new_resource} error checking repository for #{package_name}: #{e.message}")
            nil
          end

          def package_locked?(name, _version)
            logger.trace("#{new_resource} checking if package #{name} is locked")
            pkg_info = shell_out!('pkg', 'info', '-q', name, env: nil, returns: [0, 1])
            return false if pkg_info.exitstatus != 0

            # Check if package is locked using pkg query
            locked_query = shell_out!('pkg', 'query', '%k', name, env: nil, returns: [0, 1])
            if locked_query.exitstatus == 0
              locked_status = locked_query.stdout.strip
              # pkg query returns 1 if the package is locked, 0 if unlocked
              result = locked_status == '1'
              logger.trace("#{new_resource} package #{name} is #{result ? 'locked' : 'unlocked'}")
              result
            else
              # If query fails, assume package is not locked
              logger.trace("#{new_resource} could not determine lock status for #{name}, assuming unlocked")
              false
            end
          rescue => e
            logger.trace("#{new_resource} error checking lock status for #{name}: #{e.message}")
            # If query fails, assume package is not locked
            false
          end

          # Vital flag methods
          def get_vital_status(name)
            logger.trace("#{new_resource} getting vital status for package #{name}")
            vital_query = shell_out!('pkg', 'query', '%V', name, env: nil, returns: [0, 1])
            if vital_query.exitstatus == 0
              vital_status = vital_query.stdout.strip
              # pkg query returns 1 if the package is vital, 0 if not vital
              result = vital_status == '1'
              logger.trace("#{new_resource} package #{name} vital status is #{result ? 'vital' : 'not vital'}")
              result
            else
              # If query fails, assume package is not vital
              logger.trace("#{new_resource} could not determine vital status for #{name}, assuming not vital")
              false
            end
          rescue => e
            logger.trace("#{new_resource} error checking vital status for #{name}: #{e.message}")
            # If query fails, assume package is not vital
            false
          end

          def set_vital_package(name, _version)
            logger.info("#{new_resource} setting package #{name} as vital")
            result = shell_out!('pkg', 'set', '-y', '-v', '1', name, env: { 'LC_ALL' => nil }, returns: [0, 78])
            logger.debug("pkg set vital result: #{result.stdout}#{result.stderr}")
          end

          def unset_vital_package(name, _version)
            logger.info("#{new_resource} unsetting package #{name} as vital")
            result = shell_out!('pkg', 'set', '-y', '-v', '0', name, env: { 'LC_ALL' => nil }, returns: [0, 78])
            logger.debug("pkg set vital result: #{result.stdout}#{result.stderr}")
          end

          def candidate_version
            new_resource.source ? file_candidate_version : repo_candidate_version
          end

          def file_candidate_version
            new_resource.source[/#{Regexp.escape(new_resource.package_name)}-(.+)\.txz/, 1]
          end

          def repo_candidate_version
            if new_resource.repository
              repo_option = ['-r', new_resource.repository]
              logger.trace("#{new_resource} querying candidate version from repository #{new_resource.repository}")
              pkg_query = shell_out!('pkg', 'rquery', *repo_option, options, '%v', new_resource.package_name, env: nil)
              pkg_query.exitstatus == 0 ? pkg_query.stdout.strip.split("\n").last : nil
            else
              # Handle repository specified in options
              effective_options = if options && options.join(' ').match(repo_regex)
                                    ::Regexp.last_match(1).split(' ')
                                  else
                                    ['-U'] # Default to update repo before querying if no repo options specified
                                  end

              pkg_query = shell_out!('pkg', 'rquery', *effective_options, '%v', new_resource.package_name, env: nil)
              pkg_query.exitstatus == 0 ? pkg_query.stdout.strip.split("\n").last : nil
            end
          end

          def repo_regex
            /(-r\s?\S+)\b/
          end

          def handle_vital_flag(name)
            # Only process if vital is explicitly set (not nil)
            return unless !new_resource.vital.nil?

            current_vital = get_vital_status(name)

            if new_resource.vital && !current_vital
              logger.info("#{new_resource} setting package #{name} as vital")
              set_vital_package(name, nil)
            elsif !new_resource.vital && current_vital
              logger.info("#{new_resource} unsetting package #{name} as vital")
              unset_vital_package(name, nil)
            else
              logger.debug("#{new_resource} package #{name} vital status already correct (#{new_resource.vital})")
            end
          end

          def handle_vital_flag_for_package
            # Handle vital flag for the package name
            # Works with both single package and package arrays
            if new_resource.package_name.is_a?(Array)
              new_resource.package_name.each do |pkg|
                handle_vital_flag(pkg)
              end
            else
              handle_vital_flag(new_resource.package_name)
            end
          end
        end
      end
    end
  end
end
