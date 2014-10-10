require 'chef/resource/lwrp_base'
require 'chef_metal_ssh'

class Chef::Resource::SshCluster < Chef::Resource::LWRPBase
 self.resource_name = 'ssh_cluster'

 actions :create, :delete, :nothing
 default_action :create

 attribute :path, :kind_of => String, :name_attribute => true

 def after_created
   super
   ChefMetal.with_ssh_cluster(path)
   ssh_cluster_path(path)
 end
 
 def ssh_cluster_path(_path, &block)
   @@path = _path
 end
 
 def self.path
   @@path
 end
   
end
