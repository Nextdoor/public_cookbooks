#
# Cookbook Name:: nd-puppet
# Recipe:: clean
#

marker "recipe_start_rightscale"

# Make sure to stop and disable the Puppet service. If its enabled,
# when the host boots next (during a reboot, re-image, etc), Puppet
# will start automatically and have no valid SSL certificate.
service "puppet" do
  action [ :disable, :stop ]
end

# Purge (recursively!) all of the existing 'puppet state' files on a
# host, allowing it to be reconfigured from scratch by the the
# nd-puppet::config recipe.
#
node[:'nd-puppet'][:config][:state_files].each do |state_file|
  if ::File.exist?(state_file)
    log "Purging #{state_file}."

    if ::File.directory?(state_file)
      directory state_file do
        action :delete
        recursive true
      end
    else
      file state_file do
        action :delete
      end
    end
  end
end
