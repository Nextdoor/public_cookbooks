name             'nd-puppet'
maintainer       'Nextdoor, Inc.'
maintainer_email 'cookbooks@nextdoor.com'
license          'Apache 2.0'
description      'Installs/Configures Puppet'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.0.3'

depends "rightscale"

supports "ubuntu"

recipe "nd-puppet::default",
  "Installs, configures and runs Puppet"

recipe "nd-puppet::install",
  "Install the dependencies for Puppet"

recipe "nd-puppet::config",
  "Configures Puppet for its first run"

recipe "nd-puppet::clean",
  "Cleans out all traces of existing nd-puppet::config state from a host"

recipe "nd-puppet::run",
  "Executes Puppet multiple times until it exits with a 0 exit code"

# Installation Attributes
attribute "nd-puppet/default/version",
  :display_name => "Puppet Package Version",
  :description  =>
    "The Puppet version to install (apt package version number)",
  :required     => "optional",
  :category     => "Nextdoor: Puppet Settings",
  :recipes      => [ "nd-puppet::default", "nd-puppet::install" ]

# Configuration Attributes
attribute "nd-puppet/config/facts",
  :display_name => "Custom Puppet Facts",
  :description  =>
    "A list of key=value custom puppet facts that will be stored in " +
    "/etc/facter/facts.d/nd-puppet.txt and available to Puppet as " +
    "facts for your manifest compilation. eg: my_cname=foobar",
  :required     => "optional",
  :type         => "array",
  :category     => "Nextdoor: Puppet Settings",
  :recipes      => [ "nd-puppet::default", "nd-puppet::config" ]

attribute "nd-puppet/config/puppet_node",
  :display_name => "Puppet Node Name",
  :description  =>
    "Name to pass to the Puppet server as the Node Name.\n" +
    "Only used if nd-puppet/config/node_name is 'facter' and " +
    "nd-puppet/config/node_name_fact is 'puppet_node'.",
  :required     => "recommended",
  :default      => nil,
  :category     => "Nextdoor: Puppet Settings",
  :recipes      => [ "nd-puppet::default", "nd-puppet::config" ]

attribute "nd-puppet/config/node_name",
  :display_name => "Puppet Option: node_name",
  :description  =>
    "What node_name supplier to use? Either 'cert' or 'facter'. " +
    "If 'facter' is used (default) then the nd-puppet/config/" +
    "puppet_node fact is used as the node name when contacting the puppet " +
    "master. If 'cert' is used (puppet default), then the raw hostname of " +
    "the host is used instead, and the nd-puppet/config/puppet_node fact " +
    "is ignored by Puppet.", 
  :default      => "facter",
  :choice       => [ "facter", "cert" ],
  :required     => "optional",
  :category     => "Nextdoor: Puppet Settings",
  :recipes      => [ "nd-puppet::default", "nd-puppet::config", "nd-puppet::run" ]

attribute "nd-puppet/config/report",
  :display_name => "Puppet Option: report",
  :description  =>
    "Whether or not to send back Puppet Reports. Requires that your Puppet " +
    "server is configured to accept reports and handle them.",
  :default      => "true",
  :choice       => [ "true", "false" ],
  :required     => "optional",
  :category     => "Nextdoor: Puppet Settings",
  :recipes      => [ "nd-puppet::default", "nd-puppet::run" ]

attribute "nd-puppet/config/node_name_fact",
  :display_name => "Puppet Option: node_name_fact",
  :description  =>
    "If nd-puppet/config/node_name is set to 'facter', this option defines " +
    "the name of the Puppet fact to use as the node name itself. By default, " +
    "we use 'puppet_node' which is supplied as an option for you in this " +
    "cookbook. If you have another plugin or fact that you'd like to rely " +
    "on, then you can supply that fact name here and safely ignore the " +
    "nd-puppet/config/puppet_node fact above",
  :default      => "puppet_node",
  :required     => "optional",
  :category     => "Nextdoor: Puppet Settings",
  :recipes      => [ "nd-puppet::default", "nd-puppet::config", "nd-puppet::run" ]

attribute "nd-puppet/config/challenge_password",
  :display_name => "Optional challengePassword passed through the CSR.",
  :description  =>
    "Puppet 3.4+ supports the ability to pass data to the Puppet Master " +
    "through the CSR itself. If this option is supplied, the csr_attributes" +
    ".yml file is created and the challengePassword option is embedded into " +
    "the CSR.",
  :default      => nil,
  :required     => "recommended",
  :category     => "Nextdoor: Puppet Settings",
  :recipes      => [ "nd-puppet::default", "nd-puppet::config" ]

attribute "nd-puppet/config/ca_server",
  :display_name => "Puppet Certificate Authority Server Hostname",
  :description  =>
    "Puppet server to use for certificate requests.",
  :default      => "puppet",
  :required     => "recommended",
  :category     => "Nextdoor: Puppet Settings",
  :recipes      => [ "nd-puppet::default", "nd-puppet::config", "nd-puppet::run" ]

attribute "nd-puppet/config/server",
  :display_name => "Puppet Server Hostname",
  :description  =>
    "Puppet server to use for manifest compilation.",
  :default      => "puppet",
  :required     => "recommended",
  :category     => "Nextdoor: Puppet Settings",
  :recipes      => [ "nd-puppet::default", "nd-puppet::config", "nd-puppet::run" ]

attribute "nd-puppet/config/environment",
  :display_name => "Puppet Environment Name",
  :description  =>
    "Puppet environment to request",
  :default      => "production",
  :required     => "recommended",
  :category     => "Nextdoor: Puppet Settings",
  :recipes      => [ "nd-puppet::default", "nd-puppet::config", "nd-puppet::run" ]
