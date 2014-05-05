require 'json'
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

    # ## Parameters
    # cluster_path - path to the directory containing the vagrant files, which
    #                should have been created with the vagrant_cluster resource.
    def initialize(ssh_cluster_path=nil)
      @ssh_cluster_path = ssh_cluster_path
    end

    attr_reader :ssh_cluster_path

    # Inflate a provisioner from node information; we don't want to force the
    # driver to figure out what the provisioner really needs, since it varies
    # from provisioner to provisioner.
    #
    # ## Parameters
    # node - node to inflate the provisioner for
    #
    # returns a SshProvisioner
    def self.inflate(node)
      self.new
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

      @ssh_cluster_path = Chef::Resource::SshCluster.path unless @ssh_cluster_path
      raise "No SSH Cluster Defined" unless @ssh_cluster_path

      # Set up the modified node data local variable
      provisioner_options = node['normal']['provisioner_options']

      # Validate Machine Options
      ssh_options = provisioner_options['ssh_options']
      ssh_pass_or_key_error = 'Key and Pass are defined in machine options'
      ssh_pass_or_key_error << ' and merged into ssh_options for two reasons:'
      ssh_pass_or_key_error << ' first to avoid multiple entry points for both'
      ssh_pass_or_key_error << ' and second so passwords are stored in registry on disk'
      ssh_pass_or_key_error << ' and not in node attribute on chef-server'

      ssh_options.each_pair { |k,v| raise ssh_pass_or_key_error if k == "key" || k == "password" }

      begin
        unstripped_provisioner_machine_options = JSON.parse(provisioner_options['machine_options'].to_json)
      rescue
        # Maybe we exist already and yanked the options from recipe?
        # We Fail Later if we got nothin
        empty_hash = Hash.new
        unstripped_provisioner_machine_options = JSON.parse(empty_hash.to_json)
        # raise "You must Provide Machine Options so we, uh, know what to do"
      end

      # Strip out any erroneous empty hash keys so we don't overwrite non-empty
      # registered values with empty passed values
      provisioner_machine_options = JSON.parse(unstripped_current_machine_options).delete_if { |k, v| v.empty? }

      begin
        existing_provisioner_output = node['normal']['provisioner_output']
      rescue
        existing_provisioner_output = false
      end

      # See if we have existing provisioner output provisioner_url
      if existing_provisioner_output
        begin
          existing_provisioner_url = existing_provisioner_output['provisioner_url']
        rescue
          raise "WTH? HTF we have provisioner output and no provisioner_url?"
        end
      end

      current_provisioner_url = File.join(@ssh_cluster_path, node['name'], ".json")

      # Set and Validate Machine Options
      if existing_provisioner_url
        raise "Existing and Current Provisioner Urls Dont Match" unless
        current_provisioner_url == existing_provisioner_url
        begin
          existing_machine_options = JSON.parse(File.read(existing_provisioner_url))
        rescue
          raise "Can't Read existing machine registration provisioner_url"
        end
        machine_options = existing_machine_options.merge!(provisioner_machine_options)
        # Dont Search The Registry, We already Registered
        @use_machine_registry = false
        @machine_registration_file = existing_provisioner_url
      else
        # Search By Default so we dont have any stray Registry Entries,
        # Force False Explicitly For Clarity of Action
        # @use_machine_registry = true unless provisioner_options['use_machine_registry'] == false

        # On Second thought, lets try to fix stupid
        # Not Searching Registry Can Totally Harsh Your Mellow Somewhere in the Near Future... or now.
        # So, Lets Not Do That
        @machine_registration_file = current_provisioner_url
        @use_machine_registry = true
      end

      # We pass #{new_machine_registry_match} to the registration file create method so
      # we know to mark the existing $IPADDR.json one as taken
      #
      # We dont mark when we match in case it blows up before
      # actual provisioning in which case it would get orphaned
      new_machine_registry_match = false
      if @use_machine_registry
        registry_match = match_machine_options_to_registered(ssh_cluster_path, provisioner_machine_options)
        if registry_match
          machine_options = registry_match
          new_machine_registry_match = true
        else
          # If we made it this far
          # then we dont exist already and
          # we didnt match in machine registry
          machine_options = provisioner_machine_options
        end
      end

      provisioner_options['machine_options'] = machine_options
      raise "We Have No Machine Options" unless provisioner_options['machine_options']

      # Set up Provisioner Output
      provisioner_output = node['normal']['provisioner_output'] || {
        'provisioner_url' =>   "ssh:#{@machine_registration_file}",
        'name' => node['name']
      }

      Chef::Log.debug("======================================>")
      Chef::Log.debug("acquire_machine - provisioner_output.inspect: #{provisioner_output.inspect}")
      Chef::Log.debug("======================================>")

      node['normal']['provisioner_output'] = provisioner_output

      create_registration_file(action_handler, node, new_machine_registry_match)
      machine_for(node)
    end

    # Connect to machine without acquiring it
    def connect_to_machine(node)

      # Get Password If Needs To Be Got
      provisioner_url = node['normal']['provisioner_output']['provisioner_url']
      existing_machine_options = JSON.parse(File.read(provisioner_url))
      node_machine_options = node['normal']['provisioner_options']['machine_options']
      unless node_machine_options['password']
        node_machine_options['password'] = existing_machine_options['password'] ?
          existing_machine_options['password'] : nil
      end
 
      # Get Some
      machine_for(node)
    end

    def delete_machine(action_handler, node)
      convergence_strategy_for(node).delete_chef_objects(action_handler, node)
    end

    def stop_machine(action_handler, node)
      #
      # What to do What to do.
      #
      # On one level there's really only one thing to do here,
      # shellout and halt, or shutdown -h now,
      # maybe provide abitily to pass some shutdown options
      #
      # But be vewwy vewwy careful:
      #
      # you better have console...
      # or be close to your datacenter
      #
    end

    def restart_machine(action_handler, node)
      # Full Restart, POST BIOS and all
    end

    def reload_machine(action_handler, node)
      # Use `kexec` here to skip POST and BIOS and all that noise.
    end

    protected

    def get_target_connection_method(machine_options)

      target_ip   = machine_options['ip_address'] || false
      target_fqdn = machine_options['fqdn']       || false

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

    def machine_for(node)
      ChefMetal::Machine::UnixMachine.new(node, transport_for(node), convergence_strategy_for(node))
    end

    def transport_for(node)
      create_ssh_transport(node)
    end

    def convergence_strategy_for(node)
      @convergence_strategy ||= begin
        ChefMetal::ConvergenceStrategy::InstallCached.new
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
    def create_ssh_transport(node)

      provisioner_options     = node['normal']['provisioner_options']
      provisioner_ssh_options = provisioner_options['ssh_options'].dup
      machine_options         = provisioner_options['machine_options'].dup

      # We Duped It So Now We Can Zero the Node Attr. So Not Saved On Server
      provisioner_options['machine_options']['password'] =
        nil if provisioner_options['machine_options']['password']

      provisioner_options['ssh_options']['password'] =
        nil if provisioner_options['ssh_options']['password']

      ##
      # Ssh Username
      username = provisioner_options['ssh_user'] || 'root'

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - username: #{username}")
      Chef::Log.debug("======================================>")

      ##
      # Ssh Password
      ssh_pass = machine_options['password'] ? machine_options['password'] : false
      if ssh_pass
        ssh_pass_hash = Hash.new
        ssh_pass_hash = { 'password' => ssh_pass }
      end

      ##
      # Ssh Key
      ssh_keys = []
      if machine_options['keys']
        if machine_options['keys'].kind_of?(Array)
          machine_options['keys'].each do |key|
            ssh_keys << key
          end
        elsif machine_options['keys'].kind_of?(String)
          ssh_keys << machine_options['keys']
        else
          ssh_keys = false
        end
      end

      if ssh_keys
        ssh_key_hash = Hash.new
        ssh_key_hash = { 'keys' => ssh_keys }
      end

      Chef::Log.debug("======================================>")
      if ssh_pass
        Chef::Log.debug("create_ssh_transport - ssh_pass: #{ssh_pass}")
      elsif ssh_keys
        Chef::Log.debug("create_ssh_transport - ssh_key: #{ssh_keys.inpsect}")
      else
        Chef::Log.debug("create_ssh_transport - no ssh_pass or ssh_key given")
      end
      Chef::Log.debug("======================================>")

      raise "no ssh_pass or ssh_key given" unless ( ssh_pass || ssh_keys )

      provisioner_ssh_options = provisioner_ssh_options.merge!(JSON.parse(ssh_pass_hash.to_json))
      provisioner_ssh_options = provisioner_ssh_options.merge!(JSON.parse(ssh_key_hash.to_json))

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
      ssh_options = symbolize_keys(provisioner_ssh_options)

      # Validate Ssh Options
      ssh_options.each { |k,v| raise 'Invalid Shh Option' unless valid_ssh_options.include?(k) }

      Chef::Log.debug("======================================>")
      Chef::Log.debug("create_ssh_transport - ssh_options: #{ssh_options.inspect}")
      Chef::Log.debug("======================================>")

      # Now That We Validated Options, Lets Get Our Target
      @target_host = get_target_connection_method(machine_options)

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

      ChefMetal::Transport::SSH.new(@target_host, username, ssh_options, options)
    end

  end
