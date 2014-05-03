require 'chef_metal'
require 'chef/resource/ssh_cluster'
require 'chef/provider/ssh_cluster'
require 'chef/resource/ssh_target'
require 'chef/provider/ssh_target'
require 'chef_metal_ssh/ssh_provisioner'

module ChefMetal
  def self.with_ssh_cluster(cluster_path, &block)
    run_context.chef_metal.add_provisioner_options(run_context, new_options, &block)
  end
end

class Chef
  module DSL
    module Recipe
      def with_ssh_cluster(cluster_path, &block)
        with_provisioner(ChefMetalSsh::SshProvisioner.new(run_context, cluster_path), &block)
      end
    end
  end
end
