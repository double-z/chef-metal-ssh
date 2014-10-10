require 'chef/provider/lwrp_base'
require 'chef_metal/provider_action_handler'

class Chef::Provider::SshCluster < Chef::Provider::LWRPBase

  include ChefMetal::ProviderActionHandler

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    the_base_path = new_resource.path
    ChefMetal.inline_resource(self) do
      directory the_base_path
    end
  end

  action :delete do
    the_base_path = new_resource.path
    ChefMetal.inline_resource(self) do
      directory the_base_path do
        action :delete
      end
    end
  end

  def load_current_resource
  end
end
