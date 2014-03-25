#
# Cookbook Name:: nd-puppet
# Recipe:: run
#

rightscale_marker

# Determine whether or not we're going to be sending Puppet reports
# or not when we run Puppet below.
case node[:'nd-puppet'][:config][:report]
when "true"
  report="--report"
when "false"
  report="--no-report"
end

# Repeatedly execute the 'puppet agent -t' command until the command
# exits with a '0' exit code, or fails entirely.
execute "run puppet-agent" do
  command     "puppet agent -t " +
              " #{report} " +
              " --pluginsync " +
              " --allow_duplicate_certs " +
              " --detailed-exitcodes " +
              " --environment #{node[:'nd-puppet'][:config][:environment]} " +
              " --ca_server #{node[:'nd-puppet'][:config][:ca_server]} " +
              " --server #{node[:'nd-puppet'][:config][:server]} " +
              " --node_name #{node[:'nd-puppet'][:config][:node_name]} " + 
              " --node_name_fact #{node[:'nd-puppet'][:config][:node_name_fact]}" +
              " --waitforcert #{node[:'nd-puppet'][:config][:waitforcert]}"
  path        [ "/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin",
                "/sbin", "/bin" ]
  not_if      "grep \'changed: 0\' /var/lib/puppet/state/last_run_summary.yaml"
  retries     node[:'nd-puppet'][:run][:retries]
  retry_delay node[:'nd-puppet'][:run][:retry_delay]
  returns     [0]
end

# At this point, Puppet has run successfully, so we remove the tag indicating
# this host needs its cert signed.
right_link_tag "nd:puppet_state=signed"
right_link_tag "nd:puppet_secret=#{node[:'nd-puppet'][:config][:pp_preshared_key]}" do
  action :remove
end
