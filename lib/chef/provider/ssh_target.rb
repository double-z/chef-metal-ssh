require 'chef/provider/lwrp_base'
require 'chef_metal/provider_action_handler'

class Chef::Provider::SshTarget < Chef::Provider::LWRPBase

  include ChefMetal::ProviderActionHandler

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :create do
    ChefMetal.inline_resource(self) do
      file ::File.join(Chef::Resource::SshCluster.path, "#{new_resource.ip_address}.json") do
        content target_file_json
      end
    end
  end

  def load_current_resource
  end
end

def target_file_json

  # Determine contents of vm file
  target_file_content = {}
  target_file_content.merge!({ 'ip_address' => new_resource.name })
  target_file_content.merge!({ 'hostname' => new_resource.hostname }) if new_resource.hostname
  target_file_content.merge!({ 'hostname' => new_resource.hostname }) if new_resource.hostname
  target_file_content.merge!({ 'hostname' => new_resource.hostname }) if new_resource.hostname
  target_file_content.merge!({ 'hostname' => new_resource.hostname }) if new_resource.hostname

  target_file_json = target_file_content.to_json
  target_file_json

end
