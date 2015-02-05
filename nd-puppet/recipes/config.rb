#
# Cookbook Name:: nd-puppet
# Recipe:: config
#

marker "recipe_start"

# Quick decision. Is our node identifier the hostname, or the puppet node?
if node[:'nd-puppet'][:config][:puppet_node]
  pp_image_name = node[:'nd-puppet'][:config][:puppet_node]
else
  pp_image_name = node[:hostname]
end

# Generate our CSR Attributes hash.. used below.
csr_attributes = {
  'custom_attributes' => {
    '1.2.840.113549.1.9.7' => node[:'nd-puppet'][:config][:challenge_password],
  },
  'extension_requests' => {
    'pp_preshared_key' => node[:'nd-puppet'][:config][:pp_preshared_key],
    'pp_image_name'    => pp_image_name
  }
}

# Loop over every fact supplied to the trusted_facts array and add it to the
# CSR file in-order.
if node[:'nd-puppet'][:config][:trusted_facts]
  node[:'nd-puppet'][:config][:trusted_facts].each do |fact|
    # Split the key=value pair. Returns an array.
    split_fact = fact.split("=", 2)

    # Sanity check that this looks like an OID, and that there is a valid
    # key=value pair here.
    raise if not split_fact[0] =~ /^[0-9\.]+$/
    raise if not split_fact[1]

    # Finally, add the pair.
    csr_attributes['extension_requests'][split_fact[0]] = split_fact[1]
  end
end

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
  variables({
    :puppet_environment => node[:'nd-puppet'][:config][:environment],
    :puppet_node        => node[:'nd-puppet'][:config][:puppet_node],
    :puppet_server      => node[:'nd-puppet'][:config][:server],
    :puppet_ca_server   => node[:'nd-puppet'][:config][:ca_server],
    :facts              => node[:'nd-puppet'][:config][:facts],
    :hostname           => node["hostname"]
  })
end

# If the challenge_password option was supplied, then we create the
# /etc/puppet/csr_attributes.yaml file.
file "/etc/puppet/csr_attributes.yaml" do
  content csr_attributes.to_yaml
  owner  "root"
  group  "root"
  mode   0644
  not_if {File.exists?("/var/lib/puppet/ssl/certificate_requests")}
end

# Tag the host to mark it as "awaiting signature". The Puppet Masters use this
# to find the host and validate that its the right host. This tag is destroyed
# once the the puppet runs have exited sucessfully.
machine_tag "nd:puppet_state=waiting" do
  action :create
end
machine_tag "nd:puppet_secret=#{node[:'nd-puppet'][:config][:pp_preshared_key]}" do
  action :create
end
