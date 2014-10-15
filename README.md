[![Gem Version](https://badge.fury.io/rb/chef-metal-ssh.svg)](http://badge.fury.io/rb/chef-metal-ssh)

# ChefMetalSsh

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'chef-metal-ssh'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install chef-metal-ssh

## Usage

* valid machine options: one of the two is required, ip address is boss if both given

        :ip_address,
        :fqdn - this can be a shortname too as long as it resolves


* valid ssh options

        :auth_methods, 
        :bind_address, 
        :compression, 
        :compression_level, 
        :config,
        :encryption, 
        :forward_agent, 
        :hmac, 
        :host_key,
        :keepalive, 
        :keepalive_interval, 
        :kex, 
        :keys, 
        :key_data,
        :languages, 
        :logger, 
        :paranoid, 
        :password, 
        :port, 
        :proxy,
        :rekey_blocks_limit,
        :rekey_limit, 
        :rekey_packet_limit, 
        :timeout, 
        :verbose,
        :global_known_hosts_file, 
        :user_known_hosts_file, 
        :host_key_alias,
        :host_name, 
        :user, 
        :properties, 
        :passphrase, 
        :keys_only, 
        :max_pkt_size,
        :max_win_size, :send_env, 
        :use_agent

* machine resource example:

		require 'chef_metal_ssh'
		
		with_ssh_cluster("~/metal_ssh")

		machine "one" do
		  action [:ready, :converge]
		  machine_options 'ip_address' => '192.168.33.21',
		                  'ssh_options' => {
		                    'user' => 'vagrant',
		                    'password' => 'vagrant'
		                  }
		  recipe 'ssh_test::remote1'
		  notifies :create, 'machine[two]'
		  notifies :run, 'execute[run_touch1]'
		end


To test it out, clone the repo:

`git clone https://github.com/double-z/chef-metal-ssh.git`

in the root there is a Vagrantfile with 3 nodes, 1 master and 2 targets. 

FYI, nothing will get installed on your local machine in this process. 

Run:

`vagrant up`

which will bring up all 3 nodes. 

So then ssh to the master:

`vagrant ssh master`

the repo test directory has a test cookbook and `run_zero` script. its located at `/vagrant/test`

cd into the test directory:

`cd /vagrant/test`

then run:

`bash run_zero install_local` if you built the gem locally first using `rake build`

otherwise:

`bash run_zero install_rubygems`

this will install the prereqs. then run:

`bash run_zero both`

this will run the `ssh_test::both` recipe which will converge both targets, with target one
notifying target two. target one will converge the `ssh_test::remote1` recipe, target two the `ssh_test::remote2` recipe.

thats it.

party on wayne.

## Contributing

1. Fork it ( http://github.com/double-z/chef-metal-ssh/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
