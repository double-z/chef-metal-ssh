require 'json'
require 'resolv'
require 'chef_metal/driver'
require 'chef_metal/version'
require 'chef_metal/machine/basic_machine'
require 'chef_metal/machine/unix_machine'
require 'chef_metal/convergence_strategy/install_cached'
require 'chef_metal/transport/ssh'
require 'chef_metal_ssh/machine_registry'
require 'chef_metal_ssh/version'
require 'chef/resource/ssh_cluster'
require 'chef/provider/ssh_cluster'
module ChefMetalSsh
  # Provisions machines with ssh.
  class SshDriver < ChefMetal::Driver

    include ChefMetalSsh::MachineRegistry

    # ## Parameters
    # cluster_path - path to the directory containing the vagrant files, which
    #                should have been created with the vagrant_cluster resource.

    # Create a new ssh driver.
    #
    # ## Parameters
    # cluster_path - path to the directory containing the vagrant files, which
    #                should have been created with the vagrant_cluster resource.
    def initialize(driver_url, config)
      super
      scheme, cluster_path = driver_url.split(':', 2)
      @cluster_path = cluster_path
    end

    attr_reader :cluster_path

    def self.from_url(driver_url, config)
      SshDriver.new(driver_url, config)
    end

    def self.canonicalize_url(driver_url, config)
      scheme, cluster_path = driver_url.split(':', 2)
      cluster_path = File.expand_path(cluster_path || File.join(Chef::Config.config_dir, 'metal_ssh'))
      "ssh:#{cluster_path}"
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
    def allocate_machine(action_handler, machine_spec, machine_options)
      # TODO verify that the existing provisioner_url in the node is the same as ours
      ensure_ssh_cluster(action_handler)
      target_name = machine_spec.name
      target_file_path = File.join(cluster_path, "#{machine_spec.name}.json")


      # Chef::Log.debug("======================================>")
      # Chef::Log.debug("acquire_machine - provisioner_options.inspect: #{provisioner_options.inspect}")
      # Chef::Log.debug("======================================>")

      @target_host = get_target_connection_method(machine_options)

      # Chef::Log.debug("======================================>")
      # Chef::Log.debug("acquire_machine - target_host: #{@target_host}")
      # Chef::Log.debug("======================================>")

      # Set up Provisioner Output
      # TODO - make url the chef server url path? maybe disk path if zero?
      machine_spec.location = {
        'driver_url' => driver_url,
        'driver_version' => ChefMetalSsh::VERSION,
        'target_name' => target_name,
        'target_file_path' => target_file_path,
        'allocated_at' => Time.now.utc.to_s
      }

      # Chef::Log.debug("======================================>")
      # Chef::Log.debug("acquire_machine - machine_spec.inspect: #{machine_spec.inspect}")
      # Chef::Log.debug("======================================>")


    end

    def ready_machine(action_handler, machine_spec, machine_options)
      machine_for(machine_spec, machine_options)
    end

    def connect_to_machine(machine_spec, machine_options)
      machine_for(machine_spec, machine_options)
    end
    # # Connect to machine without acquiring it
    # def connect_to_machine(node)

    #   # Get Password If Needs To Be Got
    #   provisioner_url = node['normal']['provisioner_output']['provisioner_url']
    #   provisioner_path = provisioner_url.split(':', 2)[1].sub(/^\/\//, "")
    #   existing_machine_options = JSON.parse(File.read(provisioner_path)) # rescue nil
    #   node_machine_options = node['normal']['provisioner_options']['machine_options']
    #   unless node_machine_options['password']
    #     Chef::Log.debug "Password Not in Provisioner Machine Options"
    #     node_machine_options['password'] = existing_machine_options['password'] ?
    #       existing_machine_options['password'] : nil
    #   end

    #   # Get Some
    #   machine_for(machine_spec, machine_options)
    # end

    # def delete_machine(action_handler, node)
    #   convergence_strategy_for(node).delete_chef_objects(action_handler, node)
    # end

    # def stop_machine(action_handler, node)
    #   #
    #   # What to do What to do.
    #   #
    #   # On one level there's really only one thing to do here,
    #   # shellout and halt, or shutdown -h now,
    #   # maybe provide abitily to pass some shutdown options
    #   #
    #   # But be vewwy vewwy careful:
    #   #
    #   # you better have console...
    #   # or be close to your datacenter
    #   #
    # end

    # def restart_machine(action_handler, node)
    #   # Full Restart, POST BIOS and all
    # end

    # def reload_machine(action_handler, node)
    #   # Use `kexec` here to skip POST and BIOS and all that noise.
    # end

    def driver_url
      "ssh:#{cluster_path}"
    end


    protected

    def ensure_ssh_cluster(action_handler)
      _cluster_path = cluster_path
      ChefMetal.inline_resource(action_handler) do
        ssh_cluster _cluster_path
      end
    end

    def get_target_connection_method(given_machine_options)

      machine_options = symbolize_keys(given_machine_options)

      target_ip   = machine_options[:ip_address] || false
      target_fqdn = machine_options[:fqdn]       || false

      raise "no @target_host, target_ip or target_fqdn given" unless
      ( @target_host || target_ip || target_fqdn )

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

    def machine_for(machine_spec, machine_options)
      # ChefMetal::Machine::UnixMachine.new(node, transport_for(node), convergence_strategy_for(node))
      ChefMetal::Machine::UnixMachine.new(machine_spec,
                                          create_ssh_transport(machine_options),
                                          convergence_strategy_for(machine_spec, machine_options))
    end

    def transport_for(machine_options)
      create_ssh_transport(machine_options)
    end

    def convergence_strategy_for(machine_spec, machine_options)
      @unix_convergence_strategy ||= begin
        ChefMetal::ConvergenceStrategy::InstallCached.new(machine_options[:convergence_options],
                                                          config)
      end
    end

    def symbolize_keys(hash)
      hash.inject({}){|result, (key, value)|

        new_key   = case key
        when String
          key.to_sym
        else
          key
        end

        new_value = case value
        when Hash
          symbolize_keys(value)
        else
          value
        end

        result[new_key] = new_value
        result

      }
    end

    # Setup Ssh
    def create_ssh_transport(machine_options)
      machine_ssh_options = machine_options['ssh_options']

      ##
      # Ssh Username
      username = machine_ssh_options['user'] || 'root'

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - username: #{username}")
      Chef::Log.debug("======================================>")

      ##
      # Ssh Password
      ssh_pass = machine_ssh_options['password'] || false
      if ssh_pass
        ssh_pass_hash = Hash.new
        ssh_pass_hash = { 'password' => ssh_pass }
      else
        Chef::Log.info("NO PASSWORD")
      end

      ##
      # Ssh Key
      ssh_keys = []
      if machine_ssh_options['keys']
        if machine_ssh_options['keys'].kind_of?(Array)
          machine_ssh_options['keys'].each do |key|
            ssh_keys << key
          end
        elsif machine_ssh_options['keys'].kind_of?(String)
          ssh_keys << machine_ssh_options['keys']
        else
          ssh_keys = false
        end
      end

      if ssh_keys
        ssh_key_hash = Hash.new
        ssh_key_hash = { 'keys' => ssh_keys }
      end

      Chef::Log.info("======================================>")
      if ssh_pass
        Chef::Log.info("create_ssh_transport - ssh_pass: #{ssh_pass_hash.inspect}")
      elsif ssh_keys
        Chef::Log.info("create_ssh_transport - ssh_key: #{ssh_keys.inspect}")
      else
        Chef::Log.info("create_ssh_transport - no ssh_pass or ssh_key given")
      end
      Chef::Log.info("======================================>")

      raise "no ssh_pass or ssh_key given" unless ( ssh_pass || ssh_keys )

      machine_ssh_options = machine_ssh_options.merge!(ssh_pass_hash)
      machine_ssh_options = machine_ssh_options.merge!(ssh_key_hash)

      ##
      # Valid Ssh Options
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

      ##
      # Ssh Options
      ssh_options = symbolize_keys(machine_ssh_options)

      # Validate Ssh Options
      ssh_options.each { |k,v| raise 'Invalid Shh Option' unless valid_ssh_options.include?(k) }

      Chef::Log.debug "======================================>"
      Chef::Log.debug "create_ssh_transport - ssh_options: #{ssh_options.inspect}"
      Chef::Log.debug "======================================>"

      # Now That We Validated Options, Lets Get Our Target
      @target_host = get_target_connection_method(machine_ssh_options)

      # Make Sure We Can Connect
      begin
        ssh = Net::SSH.start(@target_host, username, ssh_options)
        ssh.close
        Chef::Log.debug("======================================>")
        Chef::Log.debug("ABLE to Connect to #{@target_host} using #{username} and #{ssh_options.inspect}")
        Chef::Log.debug("======================================>")
      rescue
        Chef::Log.debug("======================================>")
        Chef::Log.debug("UNABLE to Connect to #{@target_host} using #{username} and #{ssh_options.inspect}")
        Chef::Log.debug("======================================>")
        raise "UNABLE to Connect to #{@target_host} using #{username} and #{ssh_options.inspect}"
      end

      ##
      # Ssh Additional Options
      options = {}

      #Enable pty by default
      options[:ssh_pty_enable] = true

      # If we not root use sudo
      if username != 'root'
        options[:prefix] = 'sudo '
      end

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - options: #{options.inspect}")
      Chef::Log.debug("======================================>")

      ChefMetal::Transport::SSH.new(@target_host, username, ssh_options, options, config)

      # We Duped It So Now We Can Zero the Node Attr. So Not Saved On Server
      # provisioner_options['machine_options']['password'] =
      #   nil if provisioner_options['machine_options']['password']

      # provisioner_options['ssh_options']['password'] =
      #   nil if provisioner_options['ssh_options']['password']

    end

  end
end
