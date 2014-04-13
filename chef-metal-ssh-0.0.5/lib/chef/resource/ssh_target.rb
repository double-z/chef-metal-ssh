require 'chef/resource/lwrp_base'

class Chef::Resource::SshTarget < Chef::Resource::LWRPBase

  self.resource_name = 'ssh_target'
  
  actions :register

  default_action :register

  attribute :ip_address,
  	:kind_of => [String],
  	:name => true

  # TODO, get path from cluster resource
  attribute :ssh_cluster_path,
  	:kind_of => [String]
  
  attribute :mac_address,
  	:kind_of => [String]

  attribute :hostname,
  	:kind_of => [String]

  attribute :subnet,
  	:kind_of => [String]

  attribute :domain,
  	:kind_of => [String]

  attribute :fqdn,
  	:kind_of => [String]

  attribute :available, 
  	:kind_of => [String],
  	:default => "true"

  attribute :allowed_machine_types, 
  	:kind_of => [String, Array]

  attribute :assigned_machine_types, 
  	:kind_of => [String, Array]

  attribute :memory, 
  	:kind_of => [String]

  attribute :cpu_count, 
  	:kind_of => [String]

  attribute :cpu_type, 
  	:kind_of => [String]

  attribute :arch, 
  	:kind_of => [String]

end
