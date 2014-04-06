execute 'apt-get-update' do
  command 'apt-get update'
  ignore_failure true
  not_if { ::File.exists?('/var/lib/apt/periodic/update-success-stamp') }
  action :nothing
end.run_action(:run)

# use sleep with 'watch netstat -tulpn' on remote to verify zero forwarding
sleep 9
package 'vim-nox'
package 'nmap'

execute 'run_touch2_remote' do
  command "echo #{Time.now} >> /tmp/iran_remote2"
  action :run
end
