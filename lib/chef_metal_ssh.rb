require 'chef_metal'
require 'chef/resource/ssh_cluster'
require 'chef/provider/ssh_cluster'
require 'chef/resource/ssh_target'
require 'chef/provider/ssh_target'
# require 'chef_metal_ssh/machine_registry'
require 'chef_metal_ssh/ssh_driver'

class Chef
	module DSL
		module Recipe
			def with_ssh_cluster(cluster_path, &block)
				with_driver("ssh:#{cluster_path}", &block)
			end
		end
	end
end