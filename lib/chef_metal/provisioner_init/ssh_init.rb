require 'chef_metal_ssh/ssh_provisioner'

ChefMetal.add_registered_provisioner_class("ssh",
  ChefMetalSsh::SshProvisioner)
