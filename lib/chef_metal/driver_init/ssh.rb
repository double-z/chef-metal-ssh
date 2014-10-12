require 'chef_metal_ssh/ssh_driver'

ChefMetal.register_driver_class('ssh', ChefMetalSsh::SshDriver)