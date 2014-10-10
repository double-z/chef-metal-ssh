execute 'apt-get-update' do
  command 'apt-get update'
  ignore_failure true
  not_if { ::File.exists?('/var/lib/apt/periodic/update-success-stamp') }
  action :nothing
# end.run_action(:run)
end

# use sleep with 'watch netstat -tulpn' on remote to verify zero forwarding
# sleep 9

# package 'vim-nox'
# package 'nmap'
# package 'build-essential'
# package 'nginx'

execute 'run_touch1_remote' do
  command "echo #{Time.now} >> /tmp/iran_remote1"
  action :run
end
