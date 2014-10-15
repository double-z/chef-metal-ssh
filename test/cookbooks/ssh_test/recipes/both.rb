# require 'chef_metal'
require 'chef_metal_ssh'

# with_driver 'ssh'
ssh_cluster_path = "/vagrant/test/ssh_cluster"
# ssh_cluster ssh_cluster_path

with_ssh_cluster(ssh_cluster_path)

# require 'chef/config'
# with_chef_server "http://192.168.33.27:6900", {
#   :client_name => Chef::Config[:node_name],
#   :signing_key_filename => Chef::Config[:client_key]
# }
# include_recipe 'ssh_test::register_target'

with_chef_local_server :chef_repo_path => "/vagrant/test",
  :port => "8900"

machine "one" do
  action [:ready, :converge]
  # action :ready
  # action :converge
  # converge true
  # provisioner ChefMetalSsh::SshProvisioner.new
  machine_options 'ip_address' => '192.168.33.21',
                  'ssh_options' => {
                    'user' => 'vagrant',
                    'password' => 'vagrant'
                  }
  recipe 'ssh_test::remote1'
end

# machine "one" do
#   # action :converge
#   action :create
#   # converge true
#   provisioner ChefMetalSsh::SshProvisioner.new
#   provisioner_options 'target_ip' => '192.168.33.21',
#                       'ssh_user' => 'vagrant',
#                       'ssh_options' => {
#                         'password' => 'vagrant'
#                       }
#   # recipe 'ssh_test::remote1'
#   # notifies :create, 'machine[two]'
#   # notifies :converge, 'machine[two]'
#   # notifies :run, 'execute[run_touch1]'
# end

# execute 'run_touch1' do
#   command "echo #{Time.now} >> /tmp/iran1"
#   action :nothing
# end

# # ##
# # # Machine Two
# machine "two" do
#   action :create
#   # action :nothing
#   converge true
#   provisioner ChefMetalSsh::SshProvisioner.new
#   provisioner_options "ssh_options" => {
#                         'user' => 'vagrant'
#                       },
#                       'machine_options' => {
#                         'ip_address' => '192.168.33.22',
#                         'machine_types' => ['app_server', 'web_server'],
#                         'password' => 'vagrant'
#                       }
#   recipe 'ssh_test::remote1'
#   # recipe 'ssh_test::remote2'
#   # notifies :run, 'execute[run_touch2]'
# end

# machine "three" do
#   action :create
#   # action :nothing
#   # converge true
#   provisioner ChefMetalSsh::SshProvisioner.new
#   provisioner_options "ssh_options" => {
#                         'user' => 'vagrant'
#                       },
#                       'machine_options' => {
#                         'ip_address' => '192.168.33.22',
#                         'machine_types' => ['app_server', 'web_server'],
#                         'password' => 'vagrant'
#                       }
#   recipe 'ssh_test::remote1'
#   # recipe 'ssh_test::remote2'
#   # notifies :run, 'execute[run_touch2]'
# end


# execute 'run_touch2' do
#   command "echo #{Time.now} >> /tmp/iran2"
#   action :nothing
# end
