#!/usr/bin/env ruby

# source = { :v1 => 'one' }
# source = { :v1 => 'one', :v2 => 'two' }

source = {
  "available" =>  "true",
  # "allowed_machine_types" => [
  #   "app_server",
  #   "web_server"
  # ],
  "allowed_machine_types" => [
    "web_server"
  ],
  "ip_address" =>  "192.168.33.22"
}

registration = {
  "available" =>  "false",
  "ip_address" =>  "192.168.33.22",
  "mac_address" =>  "",
  "hostname" =>  "",
  "subnet" =>  "",
  "domain" =>  "",
  "fqdn" =>  "",
  "allowed_machine_types" => [
    "app_server",
    # "web_server"
  ],
  "assign_machine_types" => [

  ],
  "memory" =>  "",
  "cpu_count" =>  "",
  "cpu_type" =>  "",
  "arch" =>  ""
}

blah = false
nogonnawork = false

registration.each do |k,v|
  if source.has_key?(k)
    case v
    when String
      # see if registration value equals value in source
      begin
        if v == source[k]
          blah = true
        else
          raise 'nah'
        end
      rescue e
        nogonnawork = true
      end
    when Array
      source[k].each do |sv|
        begin
          v.each do |rv|
            if sv.include?(rv)
              puts 'includes'
              blah = true
            end
          end
        end
      end
    when Hash
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
