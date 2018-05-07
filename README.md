# Puppet module: adcli

This is a Puppet module for adcli.

Based on http://github.com/mburger/puppet-adcli (2014).

Released under the terms of Apache 2 License.


## changelog

* 07-May-2018: puppet5-port-rcgcustom: comment out domain_ou parameter since we precreate machine objects. Don't ask me why we didn't have to do this under Puppet 3.x.

* 18-Apr-2018: Port to Puppet 5.x and incorporate fixes from asa188

* 23-Mar-2015: Add replication_wait parameter to prevent module from exiting before newly-created computer objects have propagated across all domain controllers

* 12-Feb-2015: Add extra parameters (domain_ou, os_name, os_version, os_service_pack, service_names); split up the assembly of the final exec statement


## USAGE - Basic management

* Install adcli with default settings

        class { 'adcli': }

* Install a specific version of adcli package

        class { 'adcli':
          version => '1.0.1',
        }

* Disable adcli service.

        class { 'adcli':
          disable => true
        }

* Remove adcli package

        class { 'adcli':
          absent => true
        }

* Enable auditing without without making changes on existing adcli configuration *files*

        class { 'adcli':
          audit_only => true
        }

* Module dry-run: Do not make any change on *all* the resources provided by the module

        class { 'adcli':
          noops => true
        }


## USAGE - Overrides and Customizations
* Use custom sources for main config file

        class { 'adcli':
          source => [ "puppet:///modules/example42/adcli/adcli.conf-${hostname}" , "puppet:///modules/example42/adcli/adcli.conf" ],
        }


* Use custom source directory for the whole configuration dir

        class { 'adcli':
          source_dir       => 'puppet:///modules/example42/adcli/conf/',
          source_dir_purge => false, # Set to true to purge any existing file not present in $source_dir
        }

* Use custom template for main config file. Note that template and source arguments are alternative.

        class { 'adcli':
          template => 'example42/adcli/adcli.conf.erb',
        }

* Automatically include a custom subclass

        class { 'adcli':
          my_class => 'example42::my_adcli',
        }
