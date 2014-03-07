#
# Cookbook Name:: nd-puppet
# Recipe:: config
#

rightscale_marker

# Step 1 is to figure out whether or not we've been run before. If we have
# then we exit without running any of these configuration steps.
node[:'nd-puppet'][:config][:state_files].each do |file|
  if ::File.exist?(file)
    log "Found existing #{file}. Exiting cookbook to prevent damage."
    return
  end
end

# Step 2, write out the custom puppet facts configuration file.
directory "/etc/facter/facts.d" do
  recursive true
  mode      0755
  owner     "root"
  group     "root"
end

template "/etc/facter/facts.d/nd-puppet.txt" do
  source "nd-puppet.txt.erb"
  owner  "root"
  group  "root"
  mode   0644
  variables(
    :puppet_environment => node[:'nd-puppet'][:config][:environment],
    :puppet_node        => node[:'nd-puppet'][:config][:puppet_node],
    :puppet_server      => node[:'nd-puppet'][:config][:server],
    :puppet_ca_server   => node[:'nd-puppet'][:config][:ca_server],
    :facts              => node[:'nd-puppet'][:config][:facts]
  )
end

# If the challenge_password option was supplied, then we create the
# /etc/puppet/csr_attributes.yaml file.
template "/etc/puppet/csr_attributes.yaml" do
  source "csr_attributes.yaml.erb"
  owner  "root"
  group  "root"
  mode   0644
  variables(
    :challenge_password => node[:'nd-puppet'][:config][:challenge_password],
    :pp_preshared_key   => node[:'nd-puppet'][:config][:pp_preshared_key]
  )
  only_if { node[:'nd-puppet'][:config][:challenge_password] }
end

# Tag the host to mark it as "awaiting signature". The Puppet Masters use this
# to find the host and validate that its the right host. This tag is destroyed
# once the the puppet runs have exited sucessfully.
right_link_tag "nd:puppet_state=waiting"
right_link_tag "nd:puppet_secret=#{node[:'nd-puppet'][:config][:pp_preshared_key]}"
