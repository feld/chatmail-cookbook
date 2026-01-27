# frozen_string_literal: true

#
# Author:: Bryan McLellan (btm@loftninjas.org)
# Copyright:: Copyright (c) 2009 Bryan McLellan
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Ohai.plugin(:Network) do
  provides 'network', 'network/interfaces'
  provides 'counters/network', 'counters/network/interfaces'

  collect_data(:freebsd) do
    network Mash.new unless network
    network[:interfaces] ||= Mash.new
    counters Mash.new unless counters
    counters[:network] ||= Mash.new

    so = shell_out('route -n get default')
    so.stdout.lines do |line|
      if line =~ /(\w+): ([\w.]+)/
        case Regexp.last_match(1)
        when 'gateway'
          network[:default_gateway] = Regexp.last_match(2)
        when 'interface'
          network[:default_interface] = Regexp.last_match(2)
        end
      end
    end

    iface = Mash.new
    so = shell_out("#{Ohai.abs_path('/sbin/ifconfig')} -a")
    cint = nil
    so.stdout.lines do |line|
      if line =~ /^([0-9a-zA-Z.]+):\s+/
        cint = Regexp.last_match(1)
        iface[cint] = Mash.new
        if cint =~ /^(\w+)(\d+.*)/
          iface[cint][:type] = Regexp.last_match(1)
          iface[cint][:number] = Regexp.last_match(2)
        end
      end
      # call the family lladdr to match linux for consistency
      if line =~ /\s+ether (.+?)\s/
        iface[cint][:addresses] ||= Mash.new
        iface[cint][:addresses][Regexp.last_match(1)] = { 'family' => 'lladdr' }
      end
      if line =~ /\s+inet ([\d.]+) netmask ([\da-fx]+)\s*\w*\s*([\d.]*)/
        iface[cint][:addresses] ||= Mash.new
        # convert the netmask to decimal for consistency
        netmask = "#{Regexp.last_match(2)[2,
                                          2].hex}.#{Regexp.last_match(2)[4,
                                                                         2].hex}.#{Regexp.last_match(2)[6,
                                                                                                        2].hex}.#{Regexp.last_match(2)[8,
                                                                                                                                       2].hex}"
        iface[cint][:addresses][Regexp.last_match(1)] = if Regexp.last_match(3).empty?
                                                          { 'family' => 'inet', 'netmask' => netmask }
                                                        else
                                                          # found a broadcast address
                                                          { 'family' => 'inet', 'netmask' => netmask, 'broadcast' => Regexp.last_match(3) }
                                                        end
      end
      if line =~ /\s+inet6 ([a-f0-9:]+)%?(\w*)\s+prefixlen\s+(\d+)\s*\w*\s*([\da-fx]*)/
        next if Regexp.last_match(1) == '::1'
        next if Regexp.last_match(1).starts_with?('fe80')

        iface[cint][:addresses] ||= Mash.new
        iface[cint][:addresses][Regexp.last_match(1)] = if Regexp.last_match(4).empty?
                                                          { 'family' => 'inet6', 'prefixlen' => Regexp.last_match(3) }
                                                        else
                                                          # found a zone_id / scope
                                                          { 'family' => 'inet6', 'zoneid' => Regexp.last_match(2), 'prefixlen' => Regexp.last_match(3), 'scopeid' => Regexp.last_match(4) }
                                                        end
      end
      if line =~ /flags=\d+<(.+)>/
        flags = Regexp.last_match(1).split(',')
        iface[cint][:flags] = flags if flags.length.positive?
      end
      if line =~ /metric: (\d+) mtu: (\d+)/
        iface[cint][:metric] = Regexp.last_match(1)
        iface[cint][:mtu] = Regexp.last_match(2)
      end
    end

    so = shell_out('arp -an')
    so.stdout.lines do |line|
      if line =~ /\((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\) at ([a-fA-F0-9:]+) on ([0-9a-zA-Z.:-]+)/
        next unless iface[Regexp.last_match(3)] # this should never happen

        iface[Regexp.last_match(3)][:arp] ||= Mash.new
        iface[Regexp.last_match(3)][:arp][Regexp.last_match(1)] = Regexp.last_match(2).downcase
      end
    end

    network['interfaces'] = iface

    net_counters = Mash.new
    # From netstat(1), not sure of the implications:
    # Show the state of all network interfaces or a single interface
    # which have been auto-configured (interfaces statically configured
    # into a system, but not located at boot time are not shown).
    so = shell_out('netstat -ibdn')
    so.stdout.lines do |line|
      # Name    Mtu Network       Address              Ipkts Ierrs     Ibytes    Opkts Oerrs     Obytes  Coll Drop
      # ed0    1500 <Link#1>      54:52:00:68:92:85   333604    26  151905886   175472     0   24897542     0  905
      # $1                        $2                      $3    $4         $5       $6    $7         $8    $9  $10
      if line =~ /^([\w.*]+)\s+\d+\s+<Link#\d+>\s+([\w:]*)\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/
        net_counters[Regexp.last_match(1)] ||= Mash.new
        net_counters[Regexp.last_match(1)]['rx'] ||= Mash.new
        net_counters[Regexp.last_match(1)]['tx'] ||= Mash.new
        net_counters[Regexp.last_match(1)]['rx']['packets'] = Regexp.last_match(3)
        net_counters[Regexp.last_match(1)]['rx']['errors'] = Regexp.last_match(4)
        net_counters[Regexp.last_match(1)]['rx']['bytes'] = Regexp.last_match(5)
        net_counters[Regexp.last_match(1)]['tx']['packets'] = Regexp.last_match(6)
        net_counters[Regexp.last_match(1)]['tx']['errors'] = Regexp.last_match(7)
        net_counters[Regexp.last_match(1)]['tx']['bytes'] = Regexp.last_match(8)
        net_counters[Regexp.last_match(1)]['tx']['collisions'] = Regexp.last_match(9)
        net_counters[Regexp.last_match(1)]['tx']['dropped'] = Regexp.last_match(10)
      end
    end

    counters[:network][:interfaces] = net_counters
  end
end
