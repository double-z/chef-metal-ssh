node_url = "ssh:/vagrant/test/ssh_cluster/192.168.33.21.json"
cluster_path = node_url.split(':', 2)[1].sub(/^\/\//, "")
puts cluster_path

ssh_pass_or_key_error = 'error'
      ssh_options = { 'passwords' => '1' }
      ssh_options.each_pair { |k,v| raise ssh_pass_or_key_error if k == "key" || k == "password" }

new_machine = {
  "cpu_type" => "",
  "memory" => "257",
  "subnet" => "",
  "machine_types" => [
    # "app_servers",
    # "web_server"
  ],
  "ip_address" => "192.168.33.22"
}

tm = new_machine.dup

tm['memory'] = '258'


puts tm.inspect
puts new_machine.inspect