require 'chef_metal'
require 'chef_metal_ssh'
require 'chef_metal_ssh/ssh_provisioner'

ssh_cluster_path = "/vagrant/test/ssh_cluster"
with_ssh_cluster(ssh_cluster_path)
ssh_cluster ssh_cluster_path

##
# Machine One
ssh_target "192.168.33.21" do
  action :register
  # ssh_cluster_path "/vagrant/test/ssh_cluster"
  # mac_address ""
end


##
# Machine One
ssh_target "192.168.33.22" do
  action :register
  allowed_machine_types ['app_server', 'web_server']
  # ssh_cluster_path "/vagrant/test/ssh_cluster"
  # mac_address ""
end

