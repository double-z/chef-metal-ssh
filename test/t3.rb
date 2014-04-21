#!/usr/bin/env ruby

# new_machine = { :v1 => 'one' }
# new_machine = { :v1 => 'one', :v2 => 'two' }

# b = {
new_machine = {
  # "available" =>  "true",
  # "allowed_machine_types" => [
  #   "app_server",
  #   "web_server"
  # ],
  "allowed_machine_types" => [
    # "web_server"
    "web_server"
  ],
  "ip_address" =>  "192.168.33.22"
}

# new_machine = Array(b.to_a)

# if b.kind_of? Array
#   puts 'array'
#   puts b.inspect
# else
#   puts 'nope'
# end

registered_machine = [{
                        "available" =>  "false",
                        # "available" =>  "true",
                        "ip_address" =>  "192.168.33.22",
                        "mac_address" =>  "",
                        "hostname" =>  "",
                        "subnet" =>  "",
                        "domain" =>  "",
                        "fqdn" =>  "",
                        "allowed_machine_types" => [
                          "app_server",
                          "web_server"
                        ],
                        "assign_machine_types" => [

                        ],
                        "memory" =>  "",
                        "cpu_count" =>  "",
                        "cpu_type" =>  "",
                        "arch" =>  ""
}]

blah = false
nogonnawork = false

registered_machine.each do |reg_mach|
  reg_mach.each do |k,v|

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
      puts "not available key"
      # end
      if new_machine.has_key?(k)
        case v
        when String
          # see if registered_machine value equals value in new_machine
          begin
            if v == new_machine[k]
              puts 'v'
              puts v
              puts 'new_machine[k]'
              puts new_machine[k]
              blah = true
            else
              raise 'nah'
            end
          rescue e
            puts 'e'
            puts e
            nogonnawork = true
          end
        when Array
          new_machine[k].each do |sv|
            begin
              v.each do |rv|
                if sv.include?(rv)
                  puts 'includes'
                  puts rv
                  blah = true
                else
                  # puts "doesnt include"
                  #  puts rv
                  #  nogonnawork = true
                end
              end
            end
          end
        when Hash
        end
      end
    end
  end
end

if nogonnawork == false
  if blah == true
    puts "truesgdfhsfhdfjdf"
  else
    puts "falsegsdhfjsfjfsjsgj"
  end
else
  puts 'nogonnawork'
end
