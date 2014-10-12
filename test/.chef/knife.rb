chef_repo = File.join(File.dirname(__FILE__), "..")

chef_server_url "http://192.168.33.27:6900"
node_name       "stickywicket"
client_key      File.join(File.dirname(__FILE__), "stickywicket.pem")
cookbook_path   "#{chef_repo}/cookbooks"
cache_type      "BasicFile"
cache_options   :path => "#{chef_repo}/checksums"
# This file exists mainly to ensure we don't pick up knife.rb from anywhere else
local_mode true
config_dir "#{File.expand_path('..', __FILE__)}/" # Wherefore art config_dir, chef?

# Chef 11.14 binds to "localhost", which interferes with port forwarding on IPv6 machines for some reason
begin
  chef_zero.host '127.0.0.1'
rescue
end