require 'resolv'
require 'chef_metal/provisioner'
require 'chef_metal/version'
require 'chef_metal/machine/basic_machine'
require 'chef_metal/machine/unix_machine'
require 'chef_metal/convergence_strategy/install_cached'
require 'chef_metal/transport/ssh'

module ChefMetalSsh
  # Provisions machines with ssh.
  class SshProvisioner < ChefMetal::Provisioner

    def initialize()
    end

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
    #           -- provisioner_url: ssh:<@target_host>
    #           -- target_ip: the IP address of the target machine - IP or FQDN is required
    #           -- target_fqdn: The Resolvable name of the target machine - IP or FQDN is required
    #           -- ssh_user: the user to ssh as
    #           -- ssh_options: options to pass the ssh command. available options are here - https://github.com/net-ssh/net-ssh/blob/master/lib/net/ssh.rb#L61
    #
    #        node['normal']['provisioner_output'] will be populated with information
    #        about the created machine.  For ssh, it is a hash with this
    #        format:
    #
    #           -- provisioner_url: ssh:<@target_host>
    #           -- name: container name
    #
    def acquire_machine(action_handler, node)
      # TODO verify that the existing provisioner_url in the node is the same as ours

      # Set up the modified node data
      provisioner_options = node['normal']['provisioner_options']

      Chef::Log.debug("======================================>")
      Chef::Log.debug("acquire_machine - provisioner_options.inspect: #{provisioner_options.inspect}")
      Chef::Log.debug("======================================>")

      @target_host = get_target_connection_method(node)

      Chef::Log.debug("======================================>")
      Chef::Log.debug("acquire_machine - target_host: #{@target_host}")
      Chef::Log.debug("======================================>")

      # Set up Provisioner Output
      # TODO - make url the chef server url path? maybe disk path if zero?
      provisioner_output = node['normal']['provisioner_output'] || {
        'provisioner_url' =>   "ssh:#{@target_host}",
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
      @target_host = get_target_connection_method(node)

      Chef::Log.debug("======================================>")
      Chef::Log.debug("connect_to_machine - target_host: #{@target_host}")
      Chef::Log.debug("======================================>")

      machine_for(node)
    end

    def delete_machine(action_handler, node)
      convergence_strategy_for(node).delete_chef_objects(action_handler, node)
    end

    def stop_machine(action_handler, node)
      # What to do What to do.
      # On one level there's really only one thing to do here,
      # shellout and halt, or shutdown -h now,
      # maybe provide abitily to pass some shutdown options
      # But be vewwy vewwy careful, you better have console,
      # or be close to your datacenter
      true
    end

    def restart_machine(action_handler, node)
      # Full Restart, POST BIOS and all
    end

    def reload_machine(action_handler, node)
      # Use `kexec` here to skip POST and BIOS and all that noise.
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
        raise 'Invalid IP' unless ( target_ip =~ Resolv::IPv4::Regex ||
                                    target_ip =~ Resolv::IPv6::Regex )
        remote_host = target_ip
      elsif target_fqdn
        rh = Resolv::Hosts.new
        rd = Resolv.new

        begin
          rh.getaddress(target_fqdn)
          in_hosts_file = true
        rescue
          in_hosts_file = false
        end

        begin
          rd.getaddress(target_fqdn)
          in_dns = true
        rescue
          in_dns = false
        end

        raise 'Unresolvable Hostname' unless ( in_hosts_file || in_dns )
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

      provisioner_options     = node['normal']['provisioner_options']
      provisioner_ssh_options = provisioner_options['ssh_options']

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - target_host: #{@target_host}")
      Chef::Log.debug("======================================>")

      ##
      # Ssh Username
      username = ''
      username = provisioner_options['ssh_user'] || 'vagrant'

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - username: #{username}")
      Chef::Log.debug("======================================>")

      ##
      # Ssh Password
      ssh_pass = false
      ssh_pass = provisioner_ssh_options['password'] if provisioner_ssh_options['password']
      # ssh_pass = ssh_options[:password] if ssh_options[:password]

      ##
      # Ssh Key
      ssh_key = false
      ssh_key = provisioner_ssh_options['host_key'] if provisioner_ssh_options['host_key']
      
      Chef::Log.debug("======================================>")
      if ssh_pass
        Chef::Log.debug("create_ssh_transport - ssh_pass: #{ssh_pass}")
      elsif ssh_key
        Chef::Log.debug("create_ssh_transport - ssh_key: #{ssh_key}")
      else
        Chef::Log.debug("create_ssh_transport - no ssh_pass or ssh_key given")
      end
      Chef::Log.debug("======================================>")

      raise "no ssh_pass or ssh_key given" unless ( ssh_pass || ssh_key ) 
      ##
      # Ssh Main Options
      valid_ssh_options = [
        :auth_methods, :bind_address, :compression, :compression_level, :config,
        :encryption, :forward_agent, :hmac, :host_key,
        :keepalive, :keepalive_interval, :kex, :keys, :key_data,
        :languages, :logger, :paranoid, :password, :port, :proxy,
        :rekey_blocks_limit,:rekey_limit, :rekey_packet_limit, :timeout, :verbose,
        :global_known_hosts_file, :user_known_hosts_file, :host_key_alias,
        :host_name, :user, :properties, :passphrase, :keys_only, :max_pkt_size,
        :max_win_size, :send_env, :use_agent
      ]

      # Validate Ssh Options
      provisioner_ssh_options.each { |k,v| raise 'Invalid Shh Option' unless valid_ssh_options.include?(k.to_sym) }

      ##
      # Ssh Main Options
      ssh_options = {}
      ssh_options = {
        # TODO create a user known hosts file
        #          :user_known_hosts_file => provisioner_options['ssh_connect_options']['UserKnownHostsFile'],
        #          :paranoid => true,
        # :auth_methods => [ 'publickey' ],
        :keys_only => false,
        :host_key => ssh_key,
        :password => ssh_pass
      }

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - ssh_options: #{ssh_options.inspect}")
      Chef::Log.debug("======================================>")

      # Make Sure We Can Connect
      begin
        ssh = Net::SSH.start(@target_host, username, ssh_options)
        ssh.close
        Chef::Log.debug("======================================>")
        Chef::Log.debug("ABLE to Connect to #{@hostname} using #{@username} and #{@ssh_options}")
        Chef::Log.debug("======================================>")
      rescue
        Chef::Log.debug("======================================>")
        Chef::Log.debug("UNABLE to Connect to #{@hostname} using #{@username} and #{@ssh_options}")
        Chef::Log.debug("======================================>")
        raise "UNABLE to Connect to #{@hostname} using #{@username} and #{@ssh_options}"
      end

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

      ChefMetal::Transport::SSH.new(@target_host, username, ssh_options, options)
    end

  end
end
