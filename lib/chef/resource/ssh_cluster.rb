require 'chef/resource/lwrp_base'
require 'chef_metal_ssh'

class Chef::Resource::SshCluster < Chef::Resource::LWRPBase
 self.resource_name = 'ssh_cluster'

 actions :create, :delete, :nothing
 default_action :create

 attribute :path, :kind_of => String, :name_attribute => true

 def after_created
   super
   ChefMetal.with_ssh_cluster path
 end
 
 def self.path=(_path)
   @@path = _path 
 end
 
 def self.path
   @@path
 end
   
end