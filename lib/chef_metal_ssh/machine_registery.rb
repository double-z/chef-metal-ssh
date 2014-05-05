require 'chef_metal_ssh'

module ChefMetalSsh
  module MachineRegistry

    def validate_machine_options(node)

      allowed_new_machine_keys = %w{
        ssh_cluster_path
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
      }

      # Validate Machine Options
      new_machine.each { |k,v| raise 'Invalid Machine Option' unless allowed_new_machine_keys.include?(k) }

      if new_machine['cpu_type'] && ! new_machine['cpu_type'].empty?
        raise "Bad Cpu Type" unless ( new_machine['cpu_type'] == 'intel' || new_machine['cpu_type'] == 'amd' )
      end

      if new_machine['arch']
        raise "No Such Arch. Either i386 or x86_64" unless ( new_machine['arch'] == 'i386' || new_machine['arch'] == 'x86_64' )
      end

    end

    def registered_machine_is_available?(v)
      case v
      when "true"
        true
      else
        false
      end
    end

    def delete_provider_registration_file(action_handler, registry_file)
      ChefMetal.inline_resource(action_handler) do
        file registry_file do
          action :delete
        end
      end
    end

    def create_registration_file(action_handler, machine_registration_file, machine_options_json, new_machine_registry_match = false)

      if new_machine_registry_match
        delete_registry_file = ::File.join(Chef::Resource::SshCluster.path, machine_options_json['ipaddress'], '.json')
        delete_provider_registration_file(action_handler, delete_registry_file)
      end

      ChefMetal.inline_resource(action_handler) do
        file machine_registration_file do
          content machine_options_json
        end
      end

    end

    def match_machine_options_to_registered(ssh_cluster_path, machine_options)

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

        registered_machine_json = JSON.parse(File.read(registered_machine_file))

        registered_machine_json.each_pair do |k,v|

          # Check if key name is 'available' and if key value is true or false
          if k == "available"
            available_registered_machine = registered_machine_is_available?(v)
            break unless available_registered_machine

          # Otherwise See If We Match
          else
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

        #
        # So we looped through a registered machine and:
        #
        # - we matched
        #
        # - we fatally matched
        #
        # - or we got nothin and move on to the next loop
        # 
        if will_work == true && not_gonna_work == false
          @registered_machine_json = registered_machine_json
          break
        elsif ip_address_match || mac_address_match || fqdn_match || hostname_match
          error_message = 'We Matched IP, FQDN, Hostname or Mac Address'
          error_message << ' but other given machine options failed to match.'
          error_message << ' Aborting to avoid inconsistencies.'
          raise error_message
        end

      end

      ##
      # did we decide it will work?
      if @registered_machine_json

        # Strip out any erroneous empty hash keys
        # so we don't overwrite non-empty registered values
        # with empty passed values
        stripped_machine_json = JSON.parse(machine_options.to_json).delete_if {
        |k, v| v.empty? unless k == 'machine_types' }

        new_registraton_json = @registered_machine_json.merge!(stripped_machine_json)

        # We're off the market
        set_available_to_false = { "available" => "false" }
        new_registraton = new_registraton_json.merge!(JSON.parse(set_available_to_false.to_json))

        new_registraton
      else
        # wah wah wah
        false
      end
    end

  end
end
