# frozen_string_literal: true

provides :freebsd_package, platform_family: 'freebsd'

unified_mode true

description 'Use the **freebsd_package** resource to manage packages on FreeBSD with enhanced functionality.'

property :package_name, String,
         name_property: true,
         description: 'The name of the package to manage.'

property :repository, String,
         description: 'The name of the repository to install the package from.'

property :vital, [TrueClass, FalseClass, nil],
         description: 'Whether the package should be marked as vital (critical to system operation).',
         default: nil

action :install do
  provider = Chef::Provider::Package::Freebsd::Pkgng.new(new_resource, run_context)
  provider.run_action(:install)

  # Handle vital flag if explicitly set - runs after install regardless of install status
  unless new_resource.vital.nil?
    Chef::Log.debug("Checking vital flag for #{new_resource.package_name}: requested=#{new_resource.vital}")
    current_vital = provider.get_vital_status(new_resource.package_name)
    Chef::Log.debug("Current vital status for #{new_resource.package_name}: #{current_vital}")

    if new_resource.vital && !current_vital
      converge_by("set package #{new_resource.package_name} as vital") do
        Chef::Log.info("Setting package #{new_resource.package_name} as vital")
        provider.set_vital_package(new_resource.package_name, nil)
      end
    elsif !new_resource.vital && current_vital
      converge_by("unset package #{new_resource.package_name} as vital") do
        Chef::Log.info("Unsetting package #{new_resource.package_name} as vital")
        provider.unset_vital_package(new_resource.package_name, nil)
      end
    end
  end
end

action :remove do
  converge_by("remove package #{new_resource.package_name}") do
    provider = Chef::Provider::Package::Freebsd::Pkgng.new(new_resource, run_context)
    provider.run_action(:remove)
  end
end

action :upgrade do
  provider = Chef::Provider::Package::Freebsd::Pkgng.new(new_resource, run_context)
  provider.run_action(:upgrade)

  # Handle vital flag if explicitly set - runs after upgrade regardless of upgrade status
  unless new_resource.vital.nil?
    Chef::Log.debug("Checking vital flag for #{new_resource.package_name}: requested=#{new_resource.vital}")
    current_vital = provider.get_vital_status(new_resource.package_name)
    Chef::Log.debug("Current vital status for #{new_resource.package_name}: #{current_vital}")

    if new_resource.vital && !current_vital
      converge_by("set package #{new_resource.package_name} as vital") do
        Chef::Log.info("Setting package #{new_resource.package_name} as vital")
        provider.set_vital_package(new_resource.package_name, nil)
      end
    elsif !new_resource.vital && current_vital
      converge_by("unset package #{new_resource.package_name} as vital") do
        Chef::Log.info("Unsetting package #{new_resource.package_name} as vital")
        provider.unset_vital_package(new_resource.package_name, nil)
      end
    end
  end
end

action :lock do
  converge_by("lock package #{new_resource.package_name}") do
    provider = Chef::Provider::Package::Freebsd::Pkgng.new(new_resource, run_context)
    provider.load_current_resource
    unless provider.package_locked?(new_resource.package_name, nil)
      provider.lock_package(new_resource.package_name, nil)
    end
  end
end

action :unlock do
  converge_by("unlock package #{new_resource.package_name}") do
    provider = Chef::Provider::Package::Freebsd::Pkgng.new(new_resource, run_context)
    provider.load_current_resource
    provider.unlock_package(new_resource.package_name, nil) if provider.package_locked?(new_resource.package_name, nil)
  end
end

action :set_vital do
  converge_by("set package #{new_resource.package_name} as vital") do
    provider = Chef::Provider::Package::Freebsd::Pkgng.new(new_resource, run_context)
    provider.load_current_resource
    unless provider.get_vital_status(new_resource.package_name)
      provider.set_vital_package(new_resource.package_name, nil)
    end
  end
end

action :unset_vital do
  converge_by("unset package #{new_resource.package_name} as vital") do
    provider = Chef::Provider::Package::Freebsd::Pkgng.new(new_resource, run_context)
    provider.load_current_resource
    provider.unset_vital_package(new_resource.package_name, nil) if provider.get_vital_status(new_resource.package_name)
  end
end
