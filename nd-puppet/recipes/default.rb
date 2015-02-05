#
# Cookbook Name:: nd-puppet
# Recipe:: default
#

marker "recipe_start_rightscale"

include_recipe "nd-puppet::install" 
include_recipe "nd-puppet::config" 
include_recipe "nd-puppet::run" 
