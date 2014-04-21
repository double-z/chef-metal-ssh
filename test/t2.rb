#!/usr/bin/env ruby
require 'json'
# new_machine = { :v1 => 'one' }
# new_machine = { :v1 => 'one', :v2 => 'two' }

new_machine = {
  # "available" =>  "true",
  # "allowed_machine_types" => [
  #   "app_server",
  #   "web_server"
  # ],
  "allowed_machine_types" => [
    "app_servers",
    # "web_server"
    # "web_server"
  ],
  "ip_address" =>  "192.168.33.23"
}

Dir.glob('/tmp/rgm/*.json').each do |registered_machine_file|

  puts
  puts
  puts

  puts registered_machine_file
  registered_machine_data = File.read(registered_machine_file)
  registered_machine_json = JSON.parse(registered_machine_data)

  # registered_machine = {
  #   "available" =>  "false",
  #   # "available" =>  "true",
  #   "ip_address" =>  "192.168.33.22",
  #   "mac_address" =>  "",
  #   "hostname" =>  "",
  #   "subnet" =>  "",
  #   "domain" =>  "",
  #   "fqdn" =>  "",
  #   "allowed_machine_types" => [
  #     "app_server",
  #     "web_server"
  #   ],
  #   "assign_machine_types" => [

  #   ],
  #   "memory" =>  "",
  #   "cpu_count" =>  "",
  #   "cpu_type" =>  "",
  #   "arch" =>  ""
  # }

  will_work = false
  nogonnawork = false

  registered_machine_json.each do |k,v|
    if k == "available"
      puts "available key"
      case v
      when "false"
        puts "TAKEN"
        nogonnawork = true
        next
      when "true"
        puts "NOT TAKEN"
      end
    else
      # puts "not available key"
      # end
      if new_machine.has_key?(k)
        case v
        when String
          # see if registered_machine value equals value in new_machine
          begin
            if v == new_machine[k]
              puts 'value'
              puts v
              puts 'new_machine[k]'
              puts new_machine[k]
              will_work = true
            else
              raise 'nah'
            end
          rescue
            puts 'eerror'
            # puts e
            nogonnawork = true
          end
        when Array
          local_has = false
          new_machine[k].each do |sv|
            puts "sv"
            puts sv
            # begin
            v.each do |rv|
              # if sv.include?(rv)
              if sv == rv
                puts 'includes'
                puts rv
                will_work = true
                local_has = true
              end
            end
          end
          case local_has
          when false
            puts "next local_has"
            nogonnawork = true
          when true
            puts "has local_has"
          end
          # end
        when Hash
        end
      end
    end
  end

  if nogonnawork == false
    if will_work == true
      puts "truesgdfhsfhdfjdf"
      break
    else
      puts "falsegsdhfjsfjfsjsgj"
    end
  else
    puts 'nogonnawork'
  end
end
