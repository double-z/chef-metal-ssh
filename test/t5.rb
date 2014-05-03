node_url = "ssh:/vagrant/test/ssh_cluster/192.168.33.21.json"
cluster_path = node_url.split(':', 2)[1].sub(/^\/\//, "")
puts cluster_path