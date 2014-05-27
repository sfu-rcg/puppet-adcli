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
class adcli (
  $my_class             = '',
  $external_service     = '',
  $version              = 'present',
  $absent               = false,
  $audit_only           = false,
  $noops                = undef,
  $join_domain          = false,
  $domain_name          = '',
  $host_fqdn            = truncate($::hostname, 14),
  $user_name            = '',
  $user_password        = ''
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
  ### Resourced managed by the module ###
  #######################################

  # Package
  package { $adcli::package:
    ensure  => $adcli::manage_package,
    noop    => $adcli::noops,
  }

  # Join the Domain
  exec { "adcli_join_domain_${adcli::domain_name}":
    command => "/bin/bash -c '/bin/echo -n ${adcli::user_password} | /usr/sbin/adcli join --host-fqdn=${adcli::host_fqdn} ${adcli::domain_name} -U ${adcli::user_name} --stdin-password'",
    creates => '/etc/krb5.keytab',
    require => Package[$adcli::package],
    notify  => $adcli::manage_external_service
  }


  #######################################
  ### Optionally include custom class ###
  #######################################
  if $adcli::my_class {
    include $adcli::my_class
  }

}
