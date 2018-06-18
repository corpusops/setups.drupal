<?php
/* {{ansible_managed}} */
# {% set cfg = cops_drupal_vars %}
# {% set data = cfg.local_settings %}

// BASE URL --------------------------------------------------------------------
$base_url = '{{ cfg.drupal_uri }}';
{% if 'https' in cfg.drupal_uri %}
$conf['https'] = TRUE;
{% endif %}

// this is a hack for drush in site-install mode, overriding base_url with crap,
// at least you have a copy in variables, if needed
$conf['base_url'] = $base_url;

// D8 settings to "replace" $base_url configuration in D7
$conf['trusted_host_patterns'] = array('^{{ cfg.domain|replace(".", "\.") }}$');

$conf['reverse_proxy'] = {{ cfg.local_settings.reverse_proxy }};
$conf['reverse_proxy_header'] = '{{ cfg.local_settings.reverse_proxy_header }}';
$conf['reverse_proxy_addresses'] = {{ cfg.local_settings.reverse_proxy_addresses }};

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

$conf['update_free_access'] = FALSE;
$drupal_hash_salt = '{{ cfg.local_settings_drupal_hash }}';

ini_set('session.gc_probability', 1);
ini_set('session.gc_divisor', 100);
ini_set('session.gc_maxlifetime', 200000);
ini_set('session.cookie_lifetime', 2000000);



$conf['404_fast_paths_exclude'] = '/\/(?:styles)\//';
$conf['404_fast_paths'] = '/\.(?:txt|png|gif|jpe?g|css|js|ico|swf|flv|cgi|bat|pl|dll|exe|asp|yml)$/i';
$conf['404_fast_html'] = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd"><html xmlns="http://www.w3.org/1999/xhtml"><head><title>404 Not Found</title></head><body><h1>Not Found</h1><p>The requested URL "@path" was not found on this server.</p></body></html>';

$conf['allow_authorize_operations'] = FALSE;

$conf['install_profile'] = '{{ cfg.drupal_profile }}';

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
$conf['omit_vary_cookie'] = {{ cfg.local_settings.omit_vary_cookie }};
// Do not use the new image style token. it removes images from varnish and
// breaks some modules
$conf['image_allow_insecure_derivatives'] = {{ cfg.local_settings.image_allow_insecure_derivatives }};
// Imagecache
$conf['image_jpeg_quality'] = {{ cfg.local_settings.image_jpeg_quality}}; //95;

// CRON ///////////////////////////////////////////////////////////////
// disallow the poor-man cron, we do it via drush
$conf['automated_cron.settings']['interval'] = 0;
// do not limit time for cron tasks
// FIXME: elysia_cron is a D7 only module for now...
//$conf['elysia_cron_time_limit'] = 0;

{% if cfg.local_settings.smtp_used %}
// SMTP ///////////////////////////////////////////////////////////////
// FIXME: untested, check the smtp D8 module
$conf['smtp_on'] = TRUE;
$conf['smtp_host'] = "{{ cfg.local_settings_smtp.host }}";
$conf['smtp_from'] = "{{ cfg.local_settings_smtp.from }}";
$conf['smtp_fromname'] = "{{ cfg.local_settings_smtp.fromname }}";
{% for i in ['port', 'protocol', 'auth', 'username', 'password'] -%}
{%- set val = cfg['local_settings_smtp_{0}'.format(i)] -%}
{%- if val -%}
$conf['{{'smtp_{0}'.format(i)}}'] = "{{ val }}";
{% endif %}
{% endfor %}
{% endif %}

// File system ////////////////////////////////////////////////////////////////
// Warning: when PHP-FPM is chrooted, we musn't use real absolute path but only
// "absolute path in the choot"
$conf['file_public_path'] = 'sites/default/files';
$conf['file_directory_path'] = $conf['file_public_path'];

# www/sites/default/settings.php
$root = "{{ cfg.project_root }}";
$conf['file_private_path'] = '{{ cfg.private_files }}';
$conf['file_temporary_path'] = $root . '/var/tmp';
$conf['file_directory_temp'] = $conf['file_temporary_path'];
$conf['temporary_maximum_age'] = 21600; // in seconds 21600->6hours


// Cookies and cache //////////////////////////////////////////////////////////
// NO_CACHE cookie on POST (can be used by nginx microcache and Varnish)
// Enter the number of seconds to set a cookie for when a user submits any form
// on the website. This will ensure that any page they see after submitting a
// form will be dynamic and not cached.
$conf['cookie_cache_bypass_adv_cache_lifetime']= {{ data.cookie_cache_bypass_adv_cache_lifetime }};
// Choose whether or not the cookie will be set for just the path the user is
// viewing when filling out the form, or it it will be set for the entire
// website.
// Please read the Cookie Cache Bypass Advanced module readme beforealtering
// this setting
$conf['cookie_cache_bypass_adv_cookie_path']='entire_site';
// Choose when to set the cache bypass cookie. The safest time is before any
// other validation scripts run, but this may cause people spamming your forms
// to get more non-cached pages than you wish.
// The least aggressive setting is as the last submit function.
// However this setting may cause the cookie to not be set in some situations.
// ['before_validate','before_submit','after_submit','after_validate']
$conf['cookie_cache_bypass_adv_set_time']='after_validate';

// FORM cache validity (default is 6 hours, several gigbytes of useless cache),
// 1 hour should be enough
$conf['form_cache_retention_time'] = 3600;


// File system permissions ////////////////////////////////////////////////////
// default is 0775, we have user-group:www-data in sites/default/files
// when creating a new directory the first '2' will enforce keeping
// user-group as the group of files in this directory, 'others' do
// not need anything, so 2770 is good. But a 1st 0 should be added
// to say it's an octal mode (and do not add quotes)
$conf['file_chmod_directory']={{ cfg.local_settings.file_chmod_directory }};
// default is 0664
$conf['file_chmod_file']={{ cfg.local_settings.file_chmod_file }};

// ensure nothing in the default multithread shared umask will break
// our mkdir commands (chmod is not impacted, but mkdir is...)
umask(0000);

// default contact mail
$conf['site_mail'] = '{{ cfg.local_settings.site_email }}';

// Pure performance: avoid banned ip query during bootstrap.
$conf['blocked_ips'] = array();


// Log level //////////////////////////////////////////////////////////////////
// allowed values: 'hide', 'some', 'all', 'verbose'.
$conf['error_level'] = '{{ cfg.local_settings.error_level }}';

// Compression ////////////////////////////////////////////////////////////////
// Generate aggregates
$conf['preprocess_css'] = {{ cfg.local_settings.preprocess_css }};
$conf['preprocess_js'] = {{ cfg.local_settings.preprocess_js }};
// Generate gzip version of aggregates
$conf['css_gzip_compression'] = {{ cfg.local_settings.css_gzip_compression }};
$conf['js_gzip_compression'] = {{ cfg.local_settings.js_gzip_compression }};

// If compression is done on HTTPD level NEVER SET THIS to 1!
$conf['page_compression'] = {{ cfg.local_settings.page_compression }};

// reduce uneeded queries by increasing the allowed max size of cached sentences (default is 75)
$conf['locale_cache_length'] = {{ data.locale_cache_length }}; //204800;

// Define Drupal cache settings:--------------
$conf['cache'] = {{ data.cache }};
$conf['block_cache'] = {{ data.cache_block }};
// inactivate database connection if the cache backend doesn't need it (cache_page only)
// if the page is not cached the db connection will be made later
$conf['page_cache_without_database'] = FALSE;
// avoid executing veryi early hooks in case of page cached (like hook_boot)
$conf['page_cache_invoke_hooks']     = TRUE;
// this will be in Cache-Control: public max-age
$conf['page_cache_maximum_age'] = {{ data.page_cache_maximum_age }};

// This is the minimum cache validity
//$conf['cache_lifetime'] = 10800; // 0 is infinite., 10800->6h
// Broken feature (@Damien Tournoud http://drupal.org/node/1816424#comment-6730222)
// Always put 0
$conf['cache_lifetime'] = 0; // 0 is infinite., 10800->6h
// Also bypass Drupal hardcoded block cache disabled when hook_node_grant
// is implemented by at least one module
// See and apply http://drupal.org/node/1930960#comment-7124130
$conf['block_cache_bypass_node_grants'] = {{ data.block_cache_bypass_node_grants }}; // usually 1;


// AVOID SENDING emails if not in production env -------------------------------
$conf['reroute_email_enable'] = {{ cfg.local_settings.reroute_email_enable }};
$conf['reroute_email_address'] = '{{ cfg.local_settings.reroute_email_address }}';


/// Symfony
$conf['kernel.environment'] = '{{cfg.symfony_environment}}';
$conf['kernel.debug'] = {{cfg.symfony_debug}};
$conf['kernel.cache_dir'] = '{{ cfg.symfony_cache_dir }}';
$conf['kernel.logs_dir'] = '{{ cfg.symfony_logs_dir }}';


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
