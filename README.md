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

		machine "one" do
		  action :create
		  converge true
		  provisioner ChefMetalSsh::SshProvisioner.new
		  provisioner_options 'target_ip' => '192.168.33.21',
		                      'ssh_user' => 'vagrant',
		                      'ssh_connect_options' => {
		                        'ssh_pass' => 'vagrant'
		                      }
		  recipe 'ssh_test::remote1'
		  notifies :create, 'machine[two]'
		  notifies :run, 'execute[run_touch1]'
		end

To test it out, clone the repo:

`git clone https://github.com/double-z/chef-metal-ssh.git`

in the root there is a Vagrantfile with 3 nodes, 1 master and 2 targets. Run:

first run:

`rake build`

from the repo root to build the gem in the repo root `./pkg/` directory. then run:

`vagrant up`

which will bring up all 3 nodes. FYI, nothing will get installed on your local machine in this proces. So then ssh to the master:

`vagrant ssh master`

the repo test directory has a test cookbook and `run_zero` script. its located at `/vagrant/test`

cd into it:

`cd /vagrant/test`

then run:

`bash run_zero install`

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
