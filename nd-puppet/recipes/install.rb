#
# Cookbook Name:: nd-puppet
# Recipe:: install
#

marker "recipe_start"

# This is used to pick a few repos and package versions
lsb_codename = node[:'lsb'][:codename]

case lsb_codename
when "precise"
  ## Stolen from https://github.com/rightscale/rightscale_cookbooks/blob/master/cookbooks/ruby/recipes/install_1_9.rb

  # Installs ruby 1.9 with rubygems.
  ["ruby1.9.1-full", "ruby1.9.1-dev", "rubygems", "libaugeas-ruby1.9.1", "ruby-dev"].each do |pkg|
    package pkg
  end

  # Ubuntu can have multiple versions of ruby installed. Just need to run
  # 'update-alternatives' to have the OS know which version to use.
  bash "Use ruby 1.9" do
    code <<-EOH
      update-alternatives --set ruby "/usr/bin/ruby1.9.1"
      update-alternatives --set gem "/usr/bin/gem1.9.1"
    EOH
  end
else
  ["rubygems-integration", "ruby-dev"].each do |pkg|
    package pkg
  end
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
  "wget",

  # Requirements for building the right_api_client gem
  "gcc"
].each do |pkg|
  package pkg
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

# The mime-types 2.0+ gem relies on Ruby 1.9+, but most systems
# specifically come with Ruby 1.8. Mime-types is a dependency
# for the right_api_client below. (Same issue with the rest-client)
package "ruby-rest-client"

# Install the RightScale API Gems on the system for use when
# puppet interacts with the RightScale API.
#
# Specifically do not use the 1.6+ gems -- they require Ruby 2.0
# Lock to version 1.5.26 as it's the last known version that works with facter
# on both ubuntu 12 and ubuntu 14
gem_package "right_api_client" do
  version "1.5.26"
  gem_binary "/usr/bin/gem"
  options "--ignore-dependencies --no-ri --no-rdoc"
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
