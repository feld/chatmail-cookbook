# freebsd_sysctl Resource

The `freebsd_sysctl` resource manages FreeBSD sysctl parameters, allowing you to set values at runtime and configure them to persist in `/etc/sysctl.conf.local`.

## Syntax

```ruby
freebsd_sysctl 'variable_name' do
  value 'value'
  action :set
end
```

## Actions

- `:set` - Set the sysctl value at runtime (if immediate is true) and manage the sysctl.conf entry
- `:remove` - Remove the sysctl setting from runtime (if immediate is true) and remove the sysctl.conf entry

## Properties

- `variable` - Name of the sysctl variable (name property)
- `value` - Value to set for the sysctl variable (required for :set action)

## Examples

### Set a sysctl parameter and configure it to persist

```ruby
freebsd_sysctl 'kern.maxfiles' do
  value 100000
  action :set
end
```

### Set a sysctl parameter but only in the config file (not runtime)

```ruby
freebsd_sysctl 'kern.maxfilesperproc' do
  value 50000
  immediate false
  action :set
end
```

### Remove a sysctl setting

```ruby
freebsd_sysctl 'kern.maxfiles' do
  action :remove
end
```

### Set a sysctl parameter with a complex value

```ruby
freebsd_sysctl 'net.inet.tcp.mssdflt' do
  value 1460
  action :set
end
```