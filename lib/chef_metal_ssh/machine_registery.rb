
def get_registered_target
  registered_targets
  target_options_match_registered?(registered_targets, target_options)
end

def register_target(node)

  ChefMetal.inline_resource(self) do
    file ::File.join(Chef::Resource::SshCluster.path, "#{ip_address}.json") do
      content target_registration_file_json
    end
  end
end

def target_options_match_registered?(ssh_cluster_path, target_options)

  Dir.glob("#{ssh_cluster_path}/*.json").sort.each do |registered_machine_file|

    # Not Available By Default.
    available_registered_machine = false

    # Fail By Default.
    will_work      = false
    not_gonna_work = false

    puts registered_machine_file
    registered_machine_json = JSON.parse(File.read(registered_machine_file))

    registered_machine_json.each_pair do |k,v|
      if k == "available"
        available_registered_machine = true if registered_machine_is_available?(v)
        break unless available_registered_machine
      else
        if available_registered_machine
          if new_machine.has_key?(k)
            case v
            when String
              # see if registered_machine value equals value in new_machine
              if v == new_machine[k]
                will_work = true
              else
                not_gonna_work = true unless new_machine[k].nil? || new_machine[k].empty?
              end
            when Array
              Array(new_machine[k]).each do |sv|
                if v.include?(sv)
                  puts 'V INCLUDES'
                  will_work = true
                else
                  puts 'V NO INCLUDES'
                  not_gonna_work = true
                  break
                end
              end
            when Hash
            end
          end
        end
      end
    end

    # If we decided it will work and nobody said otherwise, we have a match.
    if will_work == true && not_gonna_work == false

      # Strip out any erroneous empty hash keys so we don't overwrite non-empty
      # registered values with empty passed values
      stripped_machine_json = JSON.parse(new_machine.to_json).delete_if { |k, v| v.empty? unless k == 'machine_types' }

      # Chef::Log.debug("======================================>")
      # Chef::Log.debug("machine_registration_match - stripped_machine_json: #{stripped_machine_json.inspect}")
      # Chef::Log.debug("======================================>")

      new_registraton = Hash.new
      new_registraton = registered_machine_json.merge!(stripped_machine_json)

      # We're off the market
      set_available_to_false = { "available" => "false" }
      new_registraton = new_registraton.merge!(JSON.parse(set_available_to_false.to_json))
      puts
      puts new_registraton.inspect
      break
    end

  end
end
