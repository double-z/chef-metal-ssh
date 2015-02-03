require 'chef/resource/lwrp_base'
require 'chef_metal_ssh'

class Chef::Resource::SshCluster < Chef::Resource::LWRPBase
 self.resource_name = 'ssh_cluster'

 actions :create, :delete, :nothing
 default_action :create

 attribute :path, :kind_of => String, :name_attribute => true

  def after_created
    super
    run_context.chef_metal.with_driver "ssh:#{path}"
  end

  # We are not interested in Chef's cloning behavior here. To make it match chef version after 
  #CHEF-5052, https://tickets.opscode.com/browse/CHEF-5052
  def load_prior_resource(type=nil,name=nil)
    Chef::Log.debug("Overloading #{resource_name}.load_prior_resource with NOOP")
  end
end