#
# Cookbook Name:: nd-puppet
# Recipe:: run
#

marker "recipe_start"

# Determine whether or not we're going to be sending Puppet reports
# or not when we run Puppet below.
case node[:'nd-puppet'][:config][:report]
when "true"
  report="--report"
when "false"
  report="--no-report"
end

# Push a script that will be used to execute Puppet repeatedly until
# it either fails multiple times, or executes successfully and quietly.
template "/etc/puppet/run.sh" do
  source "run.sh.erb"
  owner  "root"
  group  "root"
  mode   0755
  variables(
    :report         => report,
    :environment    => node[:'nd-puppet'][:config][:environment],
    :ca_server      => node[:'nd-puppet'][:config][:ca_server],
    :server         => node[:'nd-puppet'][:config][:server],
    :node_name      => node[:'nd-puppet'][:config][:node_name],
    :node_name_fact => node[:'nd-puppet'][:config][:node_name_fact],
    :waitforcert    => node[:'nd-puppet'][:config][:waitforcert],
    :retries        => node[:'nd-puppet'][:run][:retries]
  )
end

# Execute the puppet run script we pushed above
execute "run puppet-agent" do
  command     "/etc/puppet/run.sh"
  path        [ "/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin",
                "/sbin", "/bin" ]
  returns     [0]
end

# At this point, Puppet has run successfully, so we remove the tag indicating
# this host needs its cert signed.
machine_tag "nd:puppet_state=signed" do
  action :create
end
machine_tag "nd:puppet_secret=#{node[:'nd-puppet'][:config][:pp_preshared_key]}" do
  action :remove
end
