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

$databases = array();
$databases['default']['default'] = array(
  'driver' => '{{ddata.db_type}}',
  'database' => '{{ddata.db_name}}',
  'username' => '{{ddata.db_user}}',
  'password' => '{{ddata.db_password}}',
  'host' => '{{ddata.db_host}}',
  'prefix' => '{{ddata.db_prefix}}',
  'collation' => '{{ddata.db_collation}}',
  'namespace' => '{{ddata.db_namespace}}',
);

$settings['update_free_access'] = FALSE;
$drupal_hash_salt = '{{data.get(
    'drupal_hash',
    salt['mc_utils.generate_stored_password']('drupal_salt_'+cfg.name))}}';
$settings['hash_salt'] = $drupal_hash_salt;

ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 100);
ini_set('session.gc_maxlifetime', 200000);
ini_set('session.cookie_lifetime', 2000000);

$settings['container_yamls'][] = __DIR__ . '/services.yml';


$config['system.performance']['fast_404']['exclude_paths'] = '/\/(?:styles)\//';
$config['system.performance']['fast_404']['paths'] = '/\.(?:txt|png|gif|jpe?g|css|js|ico|swf|flv|cgi|bat|pl|dll|exe|asp|yml)$/i';
$config['system.performance']['fast_404']['html'] = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head><title>404 Not Found</title></head><body><h1>Not Found</h1><p>The requested URL "@path" was not found on this server.</p></body></html>';

$settings['allow_authorize_operations'] = FALSE;

// D8 config sync directory, better outside webroot than in a random directory in sites/default/files
$config_directories = array(
    'staging' => '{{data.conf_staging_dir}}',
    'sync' => '{{data.conf_sync_dir}}',
    'to_dev' => '{{data.conf_todev_dir}}',
);

$settings['install_profile'] = '{{ddata.drupal_profile}}';

$commonsettingsfile = DRUPAL_ROOT . "/sites/default/common.settings.php";
if (file_exists($commonsettingsfile)) {
  include_once($commonsettingsfile);
}
