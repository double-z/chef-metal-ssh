require 'chef/provisioning/ssh_driver'

Chef::Provisioning.register_driver_class('ssh', Chef::Provisioning::SshDriver)
