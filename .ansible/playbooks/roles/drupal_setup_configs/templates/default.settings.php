<?php
/* {{ansible_managed}} */
# {% set cfg = cops_drupal_vars %}

// BASE URL --------------------------------------------------------------------
$base_url = '{{ cfg.drupal_uri }}';
// this is a hack for drush in site-install mode, overriding base_url with crap,
// at least you have a copy in variables, if needed
$conf['base_url'] = $base_url;

// D8 settings to "replace" $base_url configuration in D7
$settings['trusted_host_patterns'] = array('^{{ cfg.domain|replace(".", "\.") }}$');

$settings['reverse_proxy'] = {{ cfg.local_settings.reverse_proxy }};
$settings['reverse_proxy_header'] = '{{ cfg.local_settings.reverse_proxy_header }}';
$settings['reverse_proxy_addresses'] = {{ cfg.local_settings.reverse_proxy_addresses }};

$databases = array();
$databases['default']['default'] = array(
  'driver' => '{{ cfg.db_type }}',
  'database' => '{{ cfg.db_name }}',
  'username' => '{{ cfg.db_user }}',
  'password' => '{{ cfg.db_password }}',
  'host' => '{{ cfg.db_host }}',
  {% if cfg.get('db_port', None) %}'port' => '{{ cfg.db_port }}',{%endif%}
  {% if cfg.get('db_prefix', None) %}'prefix' => '{{ cfg.db_prefix }}',{%endif%}
  {% if cfg.get('db_collation', None) %}'collation' => '{{ cfg.db_collation }}',{%endif%}
  {% if cfg.get('db_namespace', None) %}'namespace' => '{{ cfg.db_namespace }}',{%endif%}
);

$settings['update_free_access'] = FALSE;
$drupal_hash_salt = '{{ cfg.local_settings_drupal_hash }}';
$settings['hash_salt'] = $drupal_hash_salt;

ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 100);
ini_set('session.gc_maxlifetime', 200000);
ini_set('session.cookie_lifetime', 2000000);

$settings['container_yamls'][] = '{{ cfg.local_settings.container_yamls }}';


$config['system.performance']['fast_404']['exclude_paths'] = '/\/(?:styles)\//';
$config['system.performance']['fast_404']['paths'] = '/\.(?:txt|png|gif|jpe?g|css|js|ico|swf|flv|cgi|bat|pl|dll|exe|asp|yml)$/i';
$config['system.performance']['fast_404']['html'] = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head><title>404 Not Found</title></head><body><h1>Not Found</h1><p>The requested URL "@path" was not found on this server.</p></body></html>';

$settings['allow_authorize_operations'] = FALSE;

// D8 config sync directory, better outside webroot than in a random directory in sites/default/files
$config_directories = array(
    'sync' => '{{ cfg.local_settings.conf_sync_dir }}',
    // 'staging' => '{{ cfg.local_settings.conf_staging_dir }}',
    // 'to_dev' => '{{ cfg.local_settings.conf_todev_dir }}',
);

$settings['install_profile'] = '{{ cfg.drupal_profile }}';

/**
 * Vary Cookie: please Read
 *
 * By default, Drupal sends a "Vary: Cookie" HTTP header for anonymous page
 * views. This tells a HTTP proxy that it may return a page from its local
 * cache without contacting the web server, if the user sends the same Cookie
 * header as the user who originally requested the cached page. Without "Vary:
 * Cookie", authenticated users would also be served the anonymous page from
 * the cache. If the site has mostly anonymous users except a few known
 * editors/administrators, the Vary header can be omitted. This allows for
 * better caching in HTTP proxies (including reverse proxies), i.e. even if
 * clients send different cookies, they still get content served from the cache.
 * However, authenticated users should access the site directly (i.e. not use an
 * HTTP proxy, and bypass the reverse proxy if one is used) in order to avoid
 * getting cached pages from the proxy.
 */
$settings['omit_vary_cookie'] = {{ cfg.local_settings.omit_vary_cookie }};
// Do not use the new image style token. it removes images from varnish and
// breaks some modules
$config['image.settings']['allow_insecure_derivatives'] = {{ cfg.local_settings.image_allow_insecure_derivatives }};
// Imagecache
$config['system.image.gd']['jpeg_quality'] = {{ cfg.local_settings.image_jpeg_quality}}; //95;

// CRON ///////////////////////////////////////////////////////////////
// disallow the poor-man cron, we do it via drush
$config['automated_cron.settings']['interval'] = 0;
// do not limit time for cron tasks
// FIXME: elysia_cron is a D7 only module for now...
//$config['elysia_cron_time_limit'] = 0;

{% if cfg.local_settings.swiftmailer_used %}
// SMTP - SWIFTMAILER /////////////////////////////////////////////////
$config['swiftmailer.transport']['transport'] = 'smtp';
$config['swiftmailer.transport']['smtp_host'] = "{{ cfg.local_settings_smtp.host }}";
$config['swiftmailer.transport']['smtp_credential_provider'] = 'swiftmailer';
$config['swiftmailer.transport']['smtp_port'] = "{{ cfg.local_settings_smtp.port }}";
{% if cfg.local_settings_smtp.protocol %}
$config['swiftmailer.transport']['smtp_encryption'] = "{{ cfg.local_settings_smtp.protocol }}";
{% endif %}
{% if cfg.local_settings_smtp.auth %}
$config['swiftmailer.transport']['smtp_credentials'] = [
    'swiftmailer' => [
        'username' => '{{ cfg.local_settings_smtp.username }}',
        'password' => '{{ cfg.local_settings_smtp.password }}'
    ]];
{% endif %}
{% endif %}

{% if cfg.local_settings.smtp_used %}
// SMTP ///////////////////////////////////////////////////////////////
// untested, check swiftmailer instead
$config['system.mail']['smtp_on'] = TRUE;
$config['system.mail']['smtp_host'] = "{{ cfg.local_settings_smtp.host }}";
$config['system.mail']['smtp_from'] = "{{ cfg.local_settings_smtp.from }}";
$config['system.mail']['smtp_fromname'] = "{{ cfg.local_settings_smtp.fromname }}";
{% for i in ['port', 'protocol', 'auth', 'username', 'password'] %}
{%- set val = cfg['local_settings_smtp_{0}'.format(i)] %}
{%- if val %}
$config['system.mail']['{{'smtp_{0}'.format(i)}}'] = "{{ val }}";
{% endif %}{% endfor %}
{% endif %}

// File system ////////////////////////////////////////////////////////////////
// Warning: when PHP-FPM is chrooted, we musn't use real absolute path but only
// "absolute path in the choot"
$settings['file_public_path'] = 'sites/default/files';
# www/sites/default/settings.php
$root = "{{ cfg.project_root }}";
$settings['file_private_path'] = '{{ cfg.private_files }}';
$config['system.file']['path']['temporary'] = $root . '/var/tmp';
$config['system.file']['temporary_maximum_age'] = 21600; // in seconds 21600->6hours

// File system permissions ////////////////////////////////////////////////////
// default is 0775, we have user-group:www-data in sites/default/files
// when creating a new directory the first '2' will enforce keeping
// user-group as the group of files in this directory, 'others' do
// not need anything, so 2770 is good. But a 1st 0 should be added
// to say it's an octal mode (and do not add quotes)
$settings['file_chmod_directory']={{ cfg.local_settings.file_chmod_directory }};
// default is 0664
$settings['file_chmod_file']={{ cfg.local_settings.file_chmod_file }};

// ensure nothing in the default multithread shared umask will break
// our mkdir commands (chmod is not impacted, but mkdir is...)
umask(0000);

// default contact mail
$config['system.site']['mail'] = '{{ cfg.local_settings.site_email }}';

// Log level //////////////////////////////////////////////////////////////////
// allowed values: 'hide', 'some', 'all', 'verbose'.
$config['system.logging']['error_level'] = '{{ cfg.local_settings.error_level }}';

// Compression ////////////////////////////////////////////////////////////////
// Generate aggregates
$config['system.performance']['css']['preprocess'] = {{ cfg.local_settings.preprocess_css }};
$config['system.performance']['js']['preprocess'] = {{ cfg.local_settings.preprocess_js }};
// Generate gzip version of aggregates
$config['system.performance']['css']['preprocess'] = {{ cfg.local_settings.css_gzip_compression }};
$config['system.performance']['js']['preprocess'] = {{ cfg.local_settings.js_gzip_compression }};

// If compression is done on HTTPD level NEVER SET THIS to 1!
$conf['page_compression'] = {{ cfg.local_settings.page_compression }};

// Define Drupal cache settings:--------------
// this will be in Cache-Control: public max-age
$config['system.performance']['cache']['page']['max_age'] = {{ cfg.local_settings.page_cache_maximum_age }};
//FIXME: check in D8 for theses settings: (are theses settings still present? )
// --- response.gzip (was page_compression)
// --- cache.page.enabled (was cache)
// $settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null'; <-- or what?
//+cache:
//+    page:
//+        enabled: '0'
//+        max_age: '0'
//
// dev: null cache service:
// $settings['container_yamls'][] = DRUPAL_ROOT . '/sites/development.services.yml';
// in this file:
// parameters:
//  twig.config:
//    debug: true
//    auto_reload: true
//    cache: false
// -- OR
//services:
//  cache.backend.null:
//    class: Drupal\Core\Cache\NullBackendFactory
//parameters:
//  twig.config:
//    debug: true
//    auto_reload: true
//    cache: false
// $settings['cache']['bins']['render'] = 'cache.backend.null';
// $settings['cache']['bins']['dynamic_page_cache'] = 'cache.backend.null';

// AVOID SENDING emails if not in production env -------------------------------
$config['reroute_email.settings']['reroute_email_enable'] = {{ cfg.local_settings.reroute_email_enable }};
$config['reroute_email.settings']['reroute_email_address'] = '{{ cfg.local_settings.reroute_email_address }}';

// That's something not generated, anything which does not need env overrides
// could be stored in this file (and saved in git)
$projectsettingsfile = DRUPAL_ROOT . "/sites/project.settings.php";
if (file_exists($projectsettingsfile)) {
  include_once($projectsettingsfile);
}
$dprojectsettingsfile = DRUPAL_ROOT . "/sites/default/project.settings.php";
if (file_exists($dprojectsettingsfile)) {
  include_once($dprojectsettingsfile);
}

// That's for devs, of you want some non commited files
$localsettingsfile = DRUPAL_ROOT . "/sites/default/local.settings.php";
if (file_exists($localsettingsfile)) {
 include_once($localsettingsfile);
}
