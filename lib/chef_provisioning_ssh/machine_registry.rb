module ChefProvisioningSsh
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
      when "false"
        false
      when nil
        true
      else
        raise "Available Key is not true or false string"
      end
    end

    def delete_provider_registration_file(action_handler, registry_file)
      Chef::Provisioning.inline_resource(action_handler) do
        file registry_file do
          action :delete
        end
      end
    end

    def create_registration_file(action_handler, node, machine_options, new_machine_registry_match = false)

      # if machine_options.has_key?("available") && machine_options["available"] == "false"
      #   raise ""

      node['normal']['provisioner_options']['machine_options']['available'] = machine_options["available"]

      machine_registration_file = ::File.join(Chef::Resource::SshCluster.path, "#{machine_options['ip_address']}.json")

      if new_machine_registry_match
        # delete_registry_file = ::File.join(Chef::Resource::SshCluster.path, "#{machine_options_json['ipaddress']}.json")
        delete_provider_registration_file(action_handler, machine_registration_file)
      end

      machine_options_json = JSON.pretty_generate(machine_options)

      Chef::Provisioning.inline_resource(action_handler) do
        file machine_registration_file do
          content machine_options_json
        end
      end

    end

    def match_machine_options_to_registered(ssh_cluster_path, machine_options)

      ssh_cluster_machines = File.join(ssh_cluster_path, "*.json")

      Dir.glob(ssh_cluster_machines).sort.each do |registered_machine_file|

        # Not Available By Default.
        # available_registered_machine = false
        matched_machine_json = false unless matched_machine_json

        ip_address_match  = false unless ip_address_match
        mac_address_match = false unless mac_address_match
        fqdn_match        = false unless fqdn_match
        hostname_match    = false unless hostname_match
        node_name_match   = false unless node_name_match


        # Fail By Default.
        will_work         = false
        not_gonna_work    = false
        # But Assume is Available till told its not
        available_registered_machine = true unless (available_registered_machine == false)

        registered_machine_json = JSON.parse(File.read(registered_machine_file))

        ip_address_match  = (registered_machine_json['ip_address'] == machine_options['ip_address']) # rescue false
        mac_address_match = (registered_machine_json['mac_address'] == machine_options['mac_address']) # rescue false
        fqdn_match        = (registered_machine_json['fqdn'] == machine_options['fqdn']) # rescue false
        hostname_match    = (registered_machine_json['hostname'] == machine_options['hostname']) # rescue false


        registered_machine_json.each_pair do |k,v|

          # Check if key name is 'available' and if key value is true or false
          if k == "available"

            available_registered_machine =
              registered_machine_is_available?(v) if available_registered_machine

          elsif k == "node_name"
            if v == machine_options[k] && (!v.nil? || !v.empty?)
              node_name_match = true
            end
          else
            if machine_options.has_key?(k)
              case v
              when String
                # see if registered_machine value equals value in machine_options
                if v == machine_options[k] && !v.empty?
                  will_work         = true
                else
                  not_gonna_work = true unless (v.empty? ||
                                                machine_options[k].empty? ||
                                                k == "password" )
                end
              when Array
                Array(machine_options[k]).each do |sv|
                  if v.include?(sv)
                    will_work = true
                  else
                    not_gonna_work = true
                  end
                end
              when Hash
              else
                Chef::Log.debug "NOTHING?"
              end
            end
          end
        end

        # end
        # else
        #   puts "already registered"
        # end

        #
        # So we looped through a registered machine and:
        #
        # - we matched
        #
        # - we fatally matched
        #
        # - or we got nothin and move on to the next loop
        #

        if (will_work == true) && (not_gonna_work == false) && (available_registered_machine == true)
          matched_machine_json = true
          # break
        end

        error_out = false unless error_out
        error_message = 'We Matched' unless error_message
        if ip_address_match
          error_out = true unless available_registered_machine
          error_message << ' IP,'
        end

        if fqdn_match
          error_out = true unless available_registered_machine
          error_message << ' FQDN,'
        end

        if mac_address_match
          error_out = true unless available_registered_machine
          error_message << ' MAC ADDRESS,'
        end

        if hostname_match
          error_out = true unless available_registered_machine
          error_message << ' HOSTNAME,'
        end

        if node_name_match
          error_out = true unless available_registered_machine
          error_message << ' NODE NAME,'
        end

        if error_out && !available_registered_machine
          error_message << ' but they already exist.'
          error_message << ' Aborting to avoid inconsistencies.'
          raise error_message
        end

        ##
        # did we decide it will work?
        if matched_machine_json
          # Strip out any erroneous empty hash keys
          # so we don't overwrite non-empty registered values
          # with empty passed values
          stripped_machine_json = JSON.parse(machine_options.to_json).delete_if {
          |k, v| v.empty? unless k == 'machine_types' }

          new_registration_json = registered_machine_json.merge!(stripped_machine_json)

          # We're off the market
          set_available_to_false = { "available" => "false" }
          @matched_machine_json = new_registration_json.merge!(JSON.parse(set_available_to_false.to_json))

          return @matched_machine_json
          break
        else
          # wah wah wah
          @matched_machine_json = false
        end
      end
      return @matched_machine_json
    end
  end
end
