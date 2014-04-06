require 'chef_metal/provisioner'
require 'chef_metal/version'
require 'chef_metal/machine/basic_machine'
require 'chef_metal/machine/unix_machine'
require 'chef_metal/convergence_strategy/install_cached'
require 'chef_metal/transport/ssh'

module ChefMetalSsh
  # Provisions machines with ssh.
  class SshProvisioner < ChefMetal::Provisioner

    def initialize(target_host=nil)
      @target_host = target_host
    end

    attr_reader :target_host

    # Acquire a machine, generally by provisioning it.  Returns a Machine
    # object pointing at the machine, allowing useful actions like setup,
    # converge, execute, file and directory.  The Machine object will have a
    # "node" property which must be saved to the server (if it is any
    # different from the original node object).
    #
    # ## Parameters
    # action_handler - the action_handler object that provides context.
    # node - node object (deserialized json) representing this machine.  If
    #        the node has a provisioner_options hash in it, these will be used
    #        instead of options provided by the provisioner.  TODO compare and
    #        fail if different?
    #        node will have node['normal']['provisioner_options'] in it with any options.
    #        It is a hash with this format:
    #
    #           -- provisioner_url: ssh:<ssh_path>
    #           -- target_ip: the IP address of the target machine - IP or FQDN is required
    #           -- target_fqdn: The Resolvable name of the target machine - IP or FQDN is required
    #           -- ssh_user: the user to ssh as
    #           -- ssh_config: options to pass the ssh command. available options are here - https://github.com/net-ssh/net-ssh/blob/master/lib/net/ssh.rb#L61
    #
    #        node['normal']['provisioner_output'] will be populated with information
    #        about the created machine.  For ssh, it is a hash with this
    #        format:
    #
    #           -- provisioner_url: ssh:<ssh_path>
    #           -- name: container name
    #
    def acquire_machine(action_handler, node)
      # TODO verify that the existing provisioner_url in the node is the same as ours

      # Set up the modified node data
      provisioner_options = node['normal']['provisioner_options']

      Chef::Log.debug("======================================>")
      Chef::Log.debug("acquire_machine - provisioner_options.inspect: #{provisioner_options.inspect}")
      Chef::Log.debug("======================================>")

      if @target_host.nil?
        target_host  = get_target_connection_method(node)
        @target_host = target_host
      end

      Chef::Log.debug("======================================>")
      Chef::Log.debug("acquire_machine - target_host: #{target_host}")
      Chef::Log.debug("======================================>")

      # Set up Provisioner Output
      # TODO - make url the chef server url path? maybe disk path if zero?
      provisioner_output = node['normal']['provisioner_output'] || {
        'provisioner_url' =>   "ssh:#{target_host}",
        'name' => node['name']
      }

      Chef::Log.debug("======================================>")
      Chef::Log.debug("acquire_machine - provisioner_output.inspect: #{provisioner_output.inspect}")
      Chef::Log.debug("======================================>")

      node['normal']['provisioner_output'] = provisioner_output

      # Create machine object for callers to use
      machine_for(node)
    end

    # Connect to machine without acquiring it
    def connect_to_machine(node)
      if @target_host.nil?
        target_host  = get_target_connection_method(node)
        @target_host = target_host
      end

      Chef::Log.debug("======================================>")
      Chef::Log.debug("connect_to_machine - target_host: #{target_host}")
      Chef::Log.debug("======================================>")

      machine_for(node)
    end

    def delete_machine(action_handler, node)
      true
    end

    def stop_machine(action_handler, node)
      true
    end

    # Not meant to be part of public interface
    def transport_for(node)
      create_ssh_transport(node)
    end

    protected

    def get_target_connection_method(node)

      provisioner_options = node['normal']['provisioner_options']

      target_ip   = ''
      target_ip   = provisioner_options['target_ip'] || nil

      target_fqdn = ''
      target_fqdn = provisioner_options['target_fqdn'] || nil

      remote_host = ''
      if @target_host
        remote_host = @target_host
      elsif target_ip
        remote_host = target_ip
      elsif target_fqdn
        remote_host = target_fqdn
      else
        raise "aint got no target yo, that dog dont hunt"
      end

      Chef::Log.debug("======================================>")
      Chef::Log.debug("get_target_connection_method - remote_host: #{remote_host}")
      Chef::Log.debug("======================================>")

      remote_host
    end

    def machine_for(node)
      ChefMetal::Machine::UnixMachine.new(node, transport_for(node), convergence_strategy_for(node))
    end

    def convergence_strategy_for(node)
      @convergence_strategy ||= begin
        ChefMetal::ConvergenceStrategy::InstallCached.new
      end
    end

    # Setup Ssh
    def create_ssh_transport(node)
      # TODO - verify target_host resolves
      # Verify Valid IP

      provisioner_options = node['normal']['provisioner_options']

      ##
      # Ssh Target
      target_host = ''
      target_host = @target_host

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - target_host: #{target_host}")
      Chef::Log.debug("======================================>")

      ##
      # Ssh Username
      username    = ''
      username    = provisioner_options['ssh_user'] || 'vagrant'

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - username: #{username}")
      Chef::Log.debug("======================================>")

      ##
      # Ssh Password
      ssh_pass = ''
      ssh_pass = provisioner_options['ssh_connect_options']['ssh_pass']

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - ssh_pass: #{ssh_pass}")
      Chef::Log.debug("======================================>")

      ##
      # Ssh Main Options
      ssh_options = {}
      ssh_options = {
        # TODO create a user known hosts file
        #          :user_known_hosts_file => provisioner_options['ssh_connect_options']['UserKnownHostsFile'],
        #          :paranoid => true,
        # :auth_methods => [ 'publickey' ],
        :keys_only => false,
        :password => ssh_pass
      }

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - ssh_options: #{ssh_options.inspect}")
      Chef::Log.debug("======================================>")


      ##
      # Ssh Additional Options
      options = {}
      #Enable pty by default
      options[:ssh_pty_enable] = true

      if username != 'root'
        options[:prefix] = 'sudo '
      end

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - options: #{options.inspect}")
      Chef::Log.debug("======================================>")

      ChefMetal::Transport::SSH.new(target_host, username, ssh_options, options)
    end

  end
end
