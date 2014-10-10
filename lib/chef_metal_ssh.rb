require 'cheffish'
require 'chef_metal'
require 'chef/resource/ssh_cluster'
require 'chef/provider/ssh_cluster'
require 'chef/resource/ssh_target'
require 'chef/provider/ssh_target'
# require 'chef_metal_ssh/machine_registry'
require 'chef_metal_ssh/ssh_provisioner'

# module ChefMetal
#   def self.with_ssh_cluster(cluster_path, &block)
#     run_context.chef_metal.add_provisioner_options(run_context, new_options, &block)
#   end
# end

# class Chef
#   module DSL
#     module Recipe
#       def with_ssh_cluster(cluster_path, &block)
#         with_provisioner(ChefMetalSsh::SshProvisioner.new(run_context, cluster_path), &block)
#       end
#     end
#   end
# end
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

# module ChefMetalVagrant
#   def self.with_vagrant_box(run_context, box_name, vagrant_options = {}, &block)
#     if box_name.is_a?(Chef::Resource::VagrantBox)
#       new_options = { 'vagrant_options' => { 'vm.box' => box_name.name } }
#       new_options['vagrant_options']['vm.box_url'] = box_name.url if box_name.url
#     else
#       new_options = { 'vagrant_options' => { 'vm.box' => box_name } }
#     end

#     run_context.chef_metal.add_provisioner_options(new_options, &block)
#   end
# end

# class Chef
#   class Recipe
#     def with_vagrant_cluster(cluster_path, &block)
#       with_provisioner(ChefMetalVagrant::VagrantProvisioner.new(cluster_path), &block)
#     end

#     def with_vagrant_box(box_name, vagrant_options = {}, &block)
#       ChefMetalVagrant.with_vagrant_box(run_context, box_name, vagrant_options, &block)
#     end
#   end
# end