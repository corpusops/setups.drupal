<?php
/* {{ansible_managed}} */
# {% set cfg = cops_drupal_vars %}
# {% set ddata = cfg %}
# {% set data = ddata.local_settings %}

// D8 settings to "replace" $base_url configuration in D7
$settings['trusted_host_patterns'] = array('^{{ ddata.domain|replace(".", "\.") }}$');

$settings['reverse_proxy'] = {{data.reverse_proxy}};
$settings['reverse_proxy_header'] = '{{data.reverse_proxy_header}}';
$settings['reverse_proxy_addresses'] = {{data.reverse_proxy_addresses}};

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
$settings['omit_vary_cookie'] = {{data.omit_vary_cookie}};
// Do not use the new image style token. it removes images from varnish and
// breaks some modules
$config['image.settings']['allow_insecure_derivatives'] = {{ data.image_allow_insecure_derivatives }};
// Imagecache
$config['system.image.gd']['jpeg_quality'] = {{ data.image_jpeg_quality}}; //95;

// CRON ///////////////////////////////////////////////////////////////
// disallow the poor-man cron, we do it via drush
$config['automated_cron.settings']['interval'] = 0;
// do not limit time for cron tasks
// FIXME: elysia_cron is a D only module for now...
//$config['elysia_cron_time_limit'] = 0;

{% if ddata.local_settings_smtp.used %}
// SMTP ///////////////////////////////////////////////////////////////
// FIXME: untested, check the smtp D8 module
$config['system.mail']['smtp_on'] = TRUE;
$config['system.mail']['smtp_host'] = "{{ ddata.local_settings_smtp.host }}";
$config['system.mail']['smtp_from'] = "{{ ddata.local_settings_smtp.from }}";
$config['system.mail']['smtp_fromname'] = "{{ ddata.local_settings_smtp.fromname }}";
{% endif %}

// File system ////////////////////////////////////////////////////////////////
// Warning: when PHP-FPM is chrooted, we musn't use real absolute path but only
// "absolute path in the choot"
$settings['file_public_path'] = 'sites/default/files';
# www/sites/default/settings.php
$root = "{{cfg.project_root}}";
$settings['file_private_path'] = $root . '/var/private';
$config['system.file']['path']['temporary'] = $root . '/var/tmp';
$config['system.file']['temporary_maximum_age'] = 21600; // in seconds 21600->6hours

// File system permissions ////////////////////////////////////////////////////
// default is 0775, we have user-group:www-data in sites/default/files
// when creating a new directory the first '2' will enforce keeping
// user-group as the group of files in this directory, 'others' do
// not need anything, so 2770 is good. But a 1st 0 should be added
// to say it's an octal mode (and do not add quotes)
$settings['file_chmod_directory']={{data.file_chmod_directory}};
// default is 0664
$settings['file_chmod_file']={{data.file_chmod_file}};

// ensure nothing in the default multithread shared umask will break
// our mkdir commands (chmod is not impacted, but mkdir is...)
umask(0000);

// default contact mail
$config['system.site']['mail'] = '{{ data.site_email }}';

// Log level //////////////////////////////////////////////////////////////////
// allowed values: 'hide', 'some', 'all', 'verbose'.
$config['system.logging']['error_level'] = '{{ data.error_level }}';

// Compression ////////////////////////////////////////////////////////////////
// Generate aggregates
$config['system.performance']['css']['preprocess'] = {{ data.preprocess_css }};
$config['system.performance']['js']['preprocess'] = {{ data.preprocess_js }};
// Generate gzip version of aggregates
$config['system.performance']['css']['preprocess'] = {{ data.css_gzip_compression }};
$config['system.performance']['js']['preprocess'] = {{ data.js_gzip_compression }};

// If compression is done on HTTPD level NEVER SET THIS to 1!
$conf['page_compression'] = {{ data.page_compression }};

// Define Drupal cache settings:--------------
// this will be in Cache-Control: public max-age
$config['system.performance']['cache']['page']['max_age'] = {{ data.page_cache_maximum_age }};
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
$config['reroute_email.settings']['reroute_email_enable'] = {{ data.reroute_email_enable }};
$config['reroute_email.settings']['reroute_email_address'] = '{{ data.reroute_email_address }}';

$localsettingsfile = DRUPAL_ROOT . "/sites/default/local.settings.php";
if (file_exists($localsettingsfile)) {
 include_once($localsettingsfile);
}
