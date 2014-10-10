#!/usr/bin/env ruby
require 'json'

# machine_options = {
#   "cpu_type" => "",
#   "memory" => "256",
#   "subnet" => "255.255.255.0",
#   "machine_types" => [
#     # "app_servers",
#     # "web_server"
#   ],
#   "ip_address" => "192.168.33.22"
# }

machine_options = {
  "cpu_type" => "",
  "memory" => "256",
  "subnet" => "",
  "machine_types" => [
    # "app_servers",
    # "web_server"
  ],
  "ip_address" => "192.168.33.22"
}

def validate_machine_options(node)

  allowed_machine_options_keys = %w{
    machine_types
    mac_address
    ip_address
    subnet
    hostname
    domain
    fqdn
    memory
    cpu_count
    cpu_type
    arch
    password
    keys
  }

  # Validate Machine Options
  machine_options.each { |k,v| raise 'Invalid Machine Option' unless allowed_machine_options_keys.include?(k) }

  if machine_options['cpu_type'] && ! machine_options['cpu_type'].empty?
    raise "Bad Cpu Type" unless ( machine_options['cpu_type'] == 'intel' || machine_options['cpu_type'] == 'amd' )
  end

  if machine_options['arch']
    raise "No Such Arch. Either i386 or x86_64" unless ( machine_options['arch'] == 'i386' || machine_options['arch'] == 'x86_64' )
  end

end

def registered_machine_is_available?(v)
  case v
  when "false"
    false
  when "true"
    true
  end
end

def match_and_registered(ssh_cluster_path, machine_options)
  ssh_cluster_machines = File.join(ssh_cluster_path, "*.json")
  Dir.glob(ssh_cluster_machines).sort.each do |registered_machine_file|

    # Not Available By Default.
    available_registered_machine = false
    @registered_machine_json = false

    # Fail By Default.
    will_work         = false
    not_gonna_work    = false

    # Prepare To Save People From Themselves
    ip_address_match  = false
    mac_address_match = false
    fqdn_match        = false
    hostname_match    = false

    puts registered_machine_file
    registered_machine_json = JSON.parse(File.read(registered_machine_file))

    registered_machine_json.each_pair do |k,v|
      if k == "available"
        available_registered_machine = registered_machine_is_available?(v)
        break unless available_registered_machine
      else
        if available_registered_machine
          if machine_options.has_key?(k)
            case v
            when String
              # see if registered_machine value equals value in machine_options
              if v == machine_options[k]
                ip_address_match  = true if k == 'ip_address'
                mac_address_match = true if k == 'mac_address'
                fqdn_match        = true if k == 'fqdn'
                hostname_match    = true if k == 'hostname'
                will_work         = true
              else
                not_gonna_work = true unless (machine_options[k].nil? || machine_options[k].empty?)
                break if not_gonna_work
              end
            when Array
              Array(machine_options[k]).each do |sv|
                if v.include?(sv)
                  will_work = true
                else
                  not_gonna_work = true
                  break if not_gonna_work
                end
              end
            when Hash
            end
          end
        end
      end
    end
    if will_work == true && not_gonna_work == false
      @registered_machine_json = registered_machine_json
      break
    elsif ip_address_match || mac_address_match || fqdn_match || hostname_match
        error_message = 'We Matched IP, FQDN, Hostname or Mac Address'
        error_message << ' but other given machine options failed to match.'
        error_message << ' Aborting to avoid inconsistencies'
        raise error_message
    end
  end

  # If we decided it will work
  if @registered_machine_json

    # Strip out any erroneous empty hash keys so we don't overwrite non-empty
    # registered values with empty passed values
    stripped_machine_json = JSON.parse(machine_options.to_json).delete_if { |k, v| v.empty? unless k == 'machine_types' }

    # Chef::Log.debug("======================================>")
    # Chef::Log.debug("machine_registration_match - stripped_machine_json: #{stripped_machine_json.inspect}")
    # Chef::Log.debug("======================================>")

    new_registraton_json = @registered_machine_json.merge!(stripped_machine_json)

    # We're off the market
    set_available_to_false = { "available" => "false" }
    new_registraton = new_registraton_json.merge!(JSON.parse(set_available_to_false.to_json))
    return new_registraton
  else
    return "no match"
  end

end

ssh_cluster_path = '/home/js4/metal/gem/chef-metal-ssh/test/ssh_cluster'
blah = match_and_registered(ssh_cluster_path, machine_options)
puts blah
