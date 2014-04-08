require 'chef_metal'
require 'chef_metal_ssh/ssh_provisioner'

with_chef_local_server :chef_repo_path => "/vagrant/test"

##
# Machine One
machine "one" do
  action :converge
  #action :create
#  converge true
  provisioner ChefMetalSsh::SshProvisioner.new
  provisioner_options 'target_ip' => '192.168.33.21',
                      'ssh_user' => 'vagrant',
                      'ssh_options' => {
                        'password' => 'vagrant'
                      }
  recipe 'ssh_test::remote1'
#  notifies :create, 'machine[two]'
  notifies :converge, 'machine[two]'
  notifies :run, 'execute[run_touch1]'
end

execute 'run_touch1' do
  command "echo #{Time.now} >> /tmp/iran1"
  action :nothing
end

##
# Machine Two
machine "two" do
  # action :create
  action :nothing
#  converge true
  provisioner ChefMetalSsh::SshProvisioner.new
  provisioner_options 'target_ip' => '192.168.33.22',
                      'ssh_user' => 'vagrant',
                      'ssh_options' => {
                        'password' => 'vagrant'
                      }
  recipe 'ssh_test::remote2'
  notifies :run, 'execute[run_touch2]'
end

execute 'run_touch2' do
  command "echo #{Time.now} >> /tmp/iran2"
  action :nothing
end
