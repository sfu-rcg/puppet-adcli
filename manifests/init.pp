# = Class: adcli
#
# This is the main adcli class
#
#
# == Parameters
#
# Standard class parameters
# Define the general class behaviour and customizations
#
# [*my_class*]
#   Name of a custom class to autoload to manage module's customizations
#   If defined, adcli class will automatically "include $my_class"
#
# [*version*]
#   The package version, used in the ensure parameter of package type.
#   Default: present. Can be 'latest' or a specific version number.
#   Note that if the argument absent (see below) is set to true, the
#   package is removed, whatever the value of version parameter.
#
# [*absent*]
#   Set to 'true' to remove all the resources installed by the module
#   Default: false
#
# [*audit_only*]
#   Set to 'true' if you don't intend to override existing configuration files
#   and want to audit the difference between existing files and the ones
#   managed by Puppet. Default: false
#
# [*noops*]
#   Set noop metaparameter to true for all the resources managed by the module.
#   Basically you can run a dryrun for this specific module if you set
#   this to true. Default: undef
#
# Optional class parameters
#
# [*computer_name*]
#   The short hostname to use when creating a computer object for this host in
#    Active Directory. Default: current shortname of this host.
#
# [*replication_wait*]
#   Number of seconds to delay exiting this module. Performing operations on
#   the newly-created computer object tend to fail it you don't wait at least
#   90 seconds. Default: 90
#
# [*domain_ou*]
#   Destination of the computer object that will be created upon joining.
#   Default: undef, meaning AD will place it in YOURAD/Computers
#
# [*os_name*]
#   Computer object comment field. Default: undef
#
# [*os_version*]
#   Computer object comment field. Default: undef
#
# [*os_service_pack*]
#   Computer object comment field. Default: undef
#
# [*service_names*]
#   Kerberos service principals to add. Default: undef
#
# [*uppercase_hostname*]
#   Whether we should present our hostname in uppercase when joining AD.
#   Useful for maintaining consistency with clients that joined AD via Samba
#   which insists on using uppercase hostnames. Default: false


class adcli (
  String $my_class             = '',
  String $external_service     = '',
  String $version              = 'present',
  Boolean $absent              = false,
  Boolean $audit_only          = false,
  Boolean $noops               = false,
  Boolean $join_domain         = false,

  # required parameters
  String $domain_name          = '',
  String $host_fqdn            = $::fqdn,
  String $user_name            = '',
  String $user_password        = '',

  # optional parameters
  String $computer_name        = $::hostname,
  Integer $replication_wait    = 90,
  String $domain_ou            = undef,
  String $os_name              = undef,
  String $os_version           = undef,
  String $os_service_pack      = undef,
  Array[String] $service_names = undef,
  Boolean $uppercase_hostname  = false,
  ) inherits adcli::params {

  ###############################################
  ### Check certain variables for consistency ###
  ###############################################

  if $adcli::join_domain {
    if empty($adcli::domain_name) {
      fail("adcli::domain_name is required, but an empty string was given")
    }
    if empty($adcli::host_fqdn) {
      fail("adcli::host_fqdn is required, but an empty string was given")
    }
    if empty($adcli::user_name) {
      fail("adcli::user_name is required, but an empty string was given")
    }
    if empty($adcli::user_password) {
      fail("adcli::user_password is required, but an empty string was given")
    }
  }


  #################################################
  ### Definition of modules' internal variables ###
  #################################################

  # Variables defined in adcli::params
  $package=$adcli::params::package

  # Variables that apply parameters behaviours
  $manage_package = $adcli::absent ? {
    true  => 'absent',
    false => $adcli::version,
  }

  $manage_audit = $adcli::audit_only ? {
    true  => 'all',
    false => undef,
  }

  $manage_external_service = $adcli::external_service ? {
    ''      => undef,
    default => Service[$adcli::external_service]
  }

  #######################################
  ### Resources managed by the module ###
  #######################################

  # Package
  package { $adcli::package:
    ensure  => $adcli::manage_package,
    noop    => $adcli::noops,
  }


  #######################################
  ### Assemble a giant exec statement ###
  #######################################

  # required parameters first
  $exec_base = "/bin/bash -c '/bin/echo -n ${adcli::user_password} | /usr/sbin/adcli join ${adcli::domain_name} --host-fqdn=${adcli::host_fqdn} -U ${adcli::user_name}"

  if $adcli::computer_name {
    if $adcli::uppercase_hostname {
        $exec_cn = inline_template("--computer-name=<%= @hostname.upcase %>")
    } else {
        $exec_cn = "--computer-name=${adcli::computer_name}"
    }
  }
  if $domain_ou {
    $exec_dou = "--domain-ou=\"${adcli::domain_ou}\""
  }
  if $os_name {
    $exec_osn = "--os-name=\"${adcli::os_name}\""
  }
  if $os_version {
    $exec_osv = "--os-version=\"${adcli::os_version}\""
  }
  if $os_service_pack {
    $exec_sp = "--os-service-pack=\"${adcli::os_service_pack}\""
  }
  if $service_names {
    # Guess who suggested inline templates to work around
    # the lack of iteration in pre-Future Parser(tm) Puppet?
    # Again? Riley. Thanks, Riley.
    $exec_sns = inline_template("<% @service_names.each do |service_name| %> --service-name=<%= service_name %><% end %>")
  }

  # N.B. you are not seeing things; we need that trailing single quote there
  $adcli_exec = "${exec_base} ${exec_cn} ${exec_dou} ${exec_osn} ${exec_osv} ${exec_sp} ${exec_sns}'"

  # Join the Domain
  exec { "adcli_join_domain_${adcli::domain_name}":
    command => $adcli_exec,
    creates => '/etc/krb5.keytab',
    require => Package[$adcli::package],
    notify  => [$adcli::manage_external_service]
  } ~>
  exec { "adcli_join_domain_sleep_${adcli::domain_name}":
    command => "/bin/sleep ${replication_wait}",
    refreshonly => true
  }



  #######################################
  ### Optionally include custom class ###
  #######################################
  if !empty($adcli::my_class) {
    include $adcli::my_class
  }

}
