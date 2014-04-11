require 'chef_metal'
require 'chef/resource/ssh_cluster'
require 'chef/provider/ssh_cluster'
require 'chef_metal_ssh/ssh_provisioner'

module ChefMetal
  def self.with_ssh_cluster(cluster_path, &block)
    with_provisioner(ChefMetalSsh::SshProvisioner.new(cluster_path), &block)
  end
end

class Chef
  class Recipe
    def with_ssh_cluster(cluster_path, &block)
      ChefMetal.with_ssh_cluster(cluster_path, &block)
    end
  end
end
