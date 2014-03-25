#
# Cookbook Name:: nd-puppet
# Attribute:: default
#

# Puppet installation attributes
default[:'nd-puppet'][:install][:version] = nil

# Configurable Puppet configuration attributes
default[:'nd-puppet'][:config][:environment] = 'production'
default[:'nd-puppet'][:config][:server] = 'puppet'
default[:'nd-puppet'][:config][:ca_server] = 'puppet'
default[:'nd-puppet'][:config][:facts] = nil
default[:'nd-puppet'][:config][:puppet_node] = node[:fqdn]
default[:'nd-puppet'][:config][:node_name] = "facter"
default[:'nd-puppet'][:config][:node_name_fact] = "puppet_node"
default[:'nd-puppet'][:config][:challenge_password] = nil
default[:'nd-puppet'][:config][:waitforcert] = 15

# Generate a random string used to temporarily identify this host in
# RightScale with a tag (done below). This is destroyed once the host
# has had its certificate signed.
default[:'nd-puppet'][:config][:pp_preshared_key] = rand(36**8).to_s(36)


# Non-configurable Puppet configuration attributes
default[:'nd-puppet'][:config][:state_files] = [
        "/var/lib/puppet/ssl",
        "/var/lib/puppet/state",
        "/etc/facter/facts.d/nd-puppet.txt",
        "/etc/puppet/csr_attributes.yaml"]

# Puppet run attributes
default[:'nd-puppet'][:run][:retries] = 5
default[:'nd-puppet'][:run][:retry_delay] = 0
