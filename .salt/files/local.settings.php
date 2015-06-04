<?php
/* GENERATED VIA SALT -- DO NOT EDIT -- */
# {% set cfg = salt['mc_project.get_configuration'](cfg) %}
# {% set ddata = cfg.data %}
# {% set data = ddata.local_settings %}

// BASE URL --------------------------------------------------------------------
$base_url = 'http://{{ ddata.domain }}';
// this is a hack for drush in site-install mode, overriding base_url with crap,
// at least you have a copy in variables, if needed
$conf['base_url'] = $base_url;

$drupal_hash_salt = "{{salt['mc_utils.generate_stored_password']('drupal_salt_'+cfg.name)}}";

// default contact mail
// $conf['site_mail'] = '{{ data.site_email }}';

// Log level
// $conf['error_level'] = {{ data.error_level }};


// Filesystem Paths
// $conf['file_private_path'] = 'path/to/var/private';
// $conf['file_temporary_path'] = 'path/to/var/tmp';

// SMTP ///////////////////////////////////////////////////////////////
// $conf['smtp_on'] = 1;
// $conf['smtp_host'] = "{{ data.smtp.host }}";
// $conf['smtp_from'] = "{{ data.smtp.from }}";
// $conf['smtp_fromname'] = "{{ data.smtp.fromname }}";
// AVOID SENDING emails if not in production env -------------------------------
$conf['reroute_email_enable'] = {{ data.reroute_email_enable }};
$conf['reroute_email_address'] = '{{ data.reroute_email_address }}';
