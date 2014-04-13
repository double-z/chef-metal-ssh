require 'json'
require 'chef/provider/lwrp_base'
require 'chef_metal/provider_action_handler'

class Chef::Provider::SshTarget < Chef::Provider::LWRPBase

  include ChefMetal::ProviderActionHandler

  use_inline_resources

  def whyrun_supported?
    true
  end

  action :register do
    ip_address = new_resource.name
    base_ssh_cluster_path = new_resource.ssh_cluster_path
    ChefMetal.inline_resource(self) do
      # TODO - get this working
      file ::File.join(Chef::Resource::SshCluster.path, "#{ip_address}.json") do
      #file ::File.join(base_ssh_cluster_path, "#{ip_address}.json") do
        content target_registration_file_json
      end
    end
  end

  def load_current_resource
  end
end

def target_registration_file_json

  if Chef::Resource::SshCluster.path
    puts 'yup'
    puts 'yup'
    puts 'yup'
    puts 'yup'
    puts 'yup'
    puts 'yup'
    puts Chef::Resource::SshCluster.path
    puts 'yup'
    puts 'yup'
    puts 'yup'
    puts 'yup'
    puts 'yup'
  else
   puts 'nope'
   puts 'nope'
   puts 'nope'
   puts 'nope'
   puts 'nope'
   puts 'nope'
   puts 'nope'
   puts 'nope'
   puts 'nope'
  end

  # Determine contents of vm file
  target_registration_file_content = {}
  target_registration_file_content = target_registration_file_content.merge!({ 'available' => new_resource.available })
  target_registration_file_content = target_registration_file_content.merge!({ 'ip_address' => new_resource.name })
  target_registration_file_content = target_registration_file_content.merge!({ 'mac_address' => new_resource.mac_address }) if new_resource.mac_address
  target_registration_file_content = target_registration_file_content.merge!({ 'hostname' => new_resource.hostname }) if new_resource.hostname
  target_registration_file_content = target_registration_file_content.merge!({ 'subnet' => new_resource.subnet }) if new_resource.subnet
  target_registration_file_content = target_registration_file_content.merge!({ 'domain' => new_resource.domain }) if new_resource.domain
  target_registration_file_content = target_registration_file_content.merge!({ 'fqdn' => new_resource.fqdn }) if new_resource.fqdn
  target_registration_file_content = target_registration_file_content.merge!({ 'allowed_machine_types' => new_resource.allowed_machine_types }) if new_resource.allowed_machine_types
  target_registration_file_content = target_registration_file_content.merge!({ 'assigned_machine_types' => new_resource.assigned_machine_types }) if new_resource.assigned_machine_types
  target_registration_file_content = target_registration_file_content.merge!({ 'memory' => new_resource.memory }) if new_resource.memory
  target_registration_file_content = target_registration_file_content.merge!({ 'cpu_count' => new_resource.cpu_count }) if new_resource.cpu_count
  target_registration_file_content = target_registration_file_content.merge!({ 'cpu_type' => new_resource.cpu_type }) if new_resource.cpu_type
  target_registration_file_content = target_registration_file_content.merge!({ 'arch' => new_resource.arch }) if new_resource.arch

  target_registration_file_json = JSON.parse(target_registration_file_content.to_json)
  target_registration_file_json_content = JSON.pretty_generate(target_registration_file_json)
  target_registration_file_json_content

end
