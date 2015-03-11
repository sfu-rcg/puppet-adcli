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

  # required parameters
  $domain_name          = '',
  $host_fqdn            = $::fqdn,
  $user_name            = '',
  $user_password        = '',
 
  # optional parameters
  $computer_name        = $::hostname,
  $domain_ou            = undef,
  $os_name              = undef,
  $os_version           = undef,
  $os_service_pack      = undef,
  $service_names        = undef,
  $uppercase_hostname   = false,
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
    validate_string($adcli::computer_name)
    if $adcli::uppercase_hostname {
        $exec_cn = inline_template("--computer-name=<%= hostname.upcase %>\$@AD.SFU.CA")
    } else {
        $exec_cn = "--computer-name=${adcli::computer_name}"
    }
  }
  if $domain_ou {
    validate_string($domain_ou)
    $exec_dou = "--domain-ou=\"${adcli::domain_ou}\""
  }
  if $os_name {
    validate_string($os_name)
    $exec_osn = "--os-name=\"${adcli::os_name}\""
  }
  if $os_version {
    validate_string($os_version)
    $exec_osv = "--os-version=\"${adcli::os_version}\""
  }
  if $os_service_pack {
    validate_string($os_service_pack)
    $exec_sp = "--os-version=\"${adcli::os_service_pack}\""
  }
  if $service_names {
    validate_array($service_names)

    # Guess who suggested inline templates to work around
    # the lack of iteration in pre-Future Parser(tm) Puppet?
    # Again? Riley. Thanks, Riley.
    $exec_sns = inline_template("<% service_names.each do |service_name| %> --service-name=<%= service_name %><% end %>")
  }

  # N.B. you are not seeing things; we need that trailing single quote there
  $adcli_exec = "${exec_base} ${exec_cn} ${exec_dou} ${exec_osn} ${exec_osv} ${exec_sp} ${exec_sns}'"
  
  # Join the Domain
  exec { "adcli_join_domain_${adcli::domain_name}":
     command => $adcli_exec,
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
