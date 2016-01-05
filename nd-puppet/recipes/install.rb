#
# Cookbook Name:: nd-puppet
# Recipe:: install
#

marker "recipe_start"

# This is used to pick a few repos and package versions
lsb_codename = node[:'lsb'][:codename]

if lsb_codename == "trusty"
  rubygems_package = "rubygems-integration"
else
  rubygems_package = "rubygems"
end

# Install the various required packages for Puppet to function
# properly on most hosts.
[ "apt-transport-https",
  "build-essential",
  "debconf-utils",
  "git",
  "lsb-base",
  "lsb-core",
  "lsb-release",
  "lsb-security",
  rubygems_package,
  "wget",

  # Requirements for building the right_api_client gem
  "ruby-dev",
  "gcc"
].each do |pkg|
  package pkg
end

# The mime-types 2.0+ gem relies on Ruby 1.9+, but most systems
# specifically come with Ruby 1.8. Mime-types is a dependency
# for the right_api_client below. (Same issue with the rest-client)
gem_package "mime-types" do
  version "1.25"
  gem_binary "/usr/bin/gem"
  options "--no-ri --no-rdoc"
end
gem_package "rest-client" do
  version "1.8.0"
  gem_binary "/usr/bin/gem"
  options "--no-ri --no-rdoc"
end

# Install the RightScale API Gems on the system for use when
# puppet interacts with the RightScale API.
#
# Specifically do not use the 1.6+ gems -- they require Ruby 2.0
gem_package "right_api_client" do
  version "1.5.28"
  gem_binary "/usr/bin/gem"
  options "--no-ri --no-rdoc"
end

# Download the Puppetlabs Apt package that installs their repo
package_name = "puppetlabs-release-#{lsb_codename}.deb"
package_url  = "http://apt.puppetlabs.com/#{package_name}"
package_deb  = "/root/#{package_name}"

# Downoad the package
remote_file package_deb do
  source package_url
end

# Always do an aptitude update. Only execute this if it receives
# a notification below that the puppet/puppet-common packages need
# to be installed.
execute "update_aptitude" do
  command "apt-get update -o APT::Get::List-Cleanup=0"
  ignore_failure true
  action :nothing
end

# Install the puppetlabs-release package if its not already there
# (if its installed, then notify the aptitude update to occur)
dpkg_package "puppetlabs-release" do
  source package_deb
  action :install
  notifies :run, resources(:execute => "update_aptitude"), :immediately
end

# Now install Puppet with the requsted version. The puppet-common
# package is installed first, then the puppet agent package.
[ "puppet-common", "puppet" ].each do |pkg|
  package pkg do
    version node[:'nd-puppet'][:install][:version]
    options "--force-yes"
  end
end
