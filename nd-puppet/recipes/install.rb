#
# Cookbook Name:: nd-puppet
# Recipe:: install
#

rightscale_marker

# Install the various required packages for Puppet to function
# properly on most hosts.
[ "apt-transport-https",
  "debconf-utils",
  "git",
  "lsb-base",
  "lsb-core",
  "lsb-release",
  "lsb-security",
  "rubygems",
  "wget"
].each do |pkg|
  package pkg
end

# The mime-types 2.0+ gem relies on Ruby 1.9+, but most systems
# specifically come with Ruby 1.8. Mime-types is a dependency
# for the right_api_client below.
gem_package "mime-types" do
  version "1.25"
  gem_binary "/usr/bin/gem"
  options "--no-ri --no-rdoc"
end

# Install the RightScale API Gems on the system for use when
# puppet interacts with the RightScale API.
gem_package "right_api_client" do
  gem_binary "/usr/bin/gem"
  options "--no-ri --no-rdoc"
end

# Download the Puppetlabs Apt package that installs their repo
lsb_codename = node[:'lsb'][:codename]
package_name = "puppetlabs-release-#{lsb_codename}.deb"
package_url  = "http://apt.puppetlabs.com/#{package_name}"
package_deb  = "/tmp/#{package_name}"

# Downoad the package
remote_file package_deb do
  source package_url
end

# Install the package
dpkg_package "puppetlabs-release" do
  source package_deb
  action :install
end

# Always do an aptitude update. Only execute this if it receives
# a notification below that the puppet/puppet-common packages need
# to be installed.
bash "update_aptitude" do
  code <<-EOH
  apt-get update -o APT::Get::List-Cleanup="0"
  EOH
  ignore_failure true
  action :nothing
end

# Now install Puppet with the requsted version. The puppet-common
# package is installed first, then the puppet agent package.
[ "puppet-common", "puppet" ].each do |pkg|
  package pkg do
    version node[:'nd-puppet'][:install][:version]
    options "--force-yes"
    notifies :run, resources(:execute => "update_aptitude"), :immediately
  end
end
