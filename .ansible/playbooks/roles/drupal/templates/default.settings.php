<?php
/* {{ansible_managed}} */
# {% set cfg = cops_drupal_vars %}
# {% set ddata = cfg %}
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
  'host' => '{{ddata.db_host}}',
  {% if ddata.get('db_prefix', None) %}'prefix' => '{{ddata.db_prefix}}',{%endif%}
  {% if ddata.get('db_collation', None) %}'collation' => '{{ddata.db_collation}}',{%endif%}
  {% if ddata.get('db_namespace', None) %}'namespace' => '{{ddata.db_namespace}}',{%endif%}
);

$settings['update_free_access'] = FALSE;
$drupal_hash_salt = '{{ddata.local_settings_drupal_hash}}';
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
    'sync' => '{{data.conf_sync_dir}}',
    // 'staging' => '{{data.conf_staging_dir}}',
    // 'to_dev' => '{{data.conf_todev_dir}}',
);

$settings['install_profile'] = '{{ddata.drupal_profile}}';

$commonsettingsfile = DRUPAL_ROOT . "/sites/default/common.settings.php";
if (file_exists($commonsettingsfile)) {
  include_once($commonsettingsfile);
}
