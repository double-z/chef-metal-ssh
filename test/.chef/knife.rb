chef_repo = File.join(File.dirname(__FILE__), "..")

chef_server_url "http://192.168.33.27:6900"
node_name       "stickywicket"
client_key      File.join(File.dirname(__FILE__), "stickywicket.pem")
cookbook_path   "#{chef_repo}/cookbooks"
cache_type      "BasicFile"
cache_options   :path => "#{chef_repo}/checksums"
