<?php
/* GENERATED VIA SALT -- DO NOT EDIT -- */
{% set cfg = salt['mc_utils.json_load'](cfg) %}
{% set ddata = cfg.data %}
{% set data = ddata.local_settings %}
$databases = array();
$databases['default']['default'] = array(
  'driver' => '{{ddata.db_type}}',
  'database' => '{{ddata.db_name}}',
  'username' => '{{ddata.db_user}}',
  'password' => '{{ddata.db_password}}',
  'host' => '{{ddata.db_host}}',
  'prefix' => '{{ddata.db_prefix}}',
);

$update_free_access = FALSE;
$drupal_hash_salt = '{{data.get(
       'drupal_hash', 
       salt['mc_utils.generate_stored_password']('drupal_salt_'+cfg.name))}}';

ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 100);
ini_set('session.gc_maxlifetime', 200000);
ini_set('session.cookie_lifetime', 2000000);

$conf['404_fast_paths_exclude'] = '/\/(?:styles)\//';
$conf['404_fast_paths'] = '/\.(?:txt|png|gif|jpe?g|css|js|ico|swf|flv|cgi|bat|pl|dll|exe|asp)$/i';
$conf['404_fast_html'] = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head><title>404 Not Found</title></head><body><h1>Not Found</h1><p>The requested URL "@path" was not found on this server.</p></body></html>';

$conf['allow_authorize_operations'] = FALSE;
$localsettingsfile = DRUPAL_ROOT . "/sites/default/common.settings.php";
if (file_exists($localsettingsfile)) {
 include_once($localsettingsfile);
}
