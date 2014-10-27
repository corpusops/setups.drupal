<?php
/* GENERATED VIA SALT -- DO NOT EDIT -- */
{% set cfg = salt['mc_utils.json_load'](cfg) %}
{% set ddata = cfg.data %}
{% set data = ddata.local_settings %}

$conf['reverse_proxy'] = {{data.reverse_proxy}};
$conf['reverse_proxy_header'] = '{{data.reverse_proxy_header}}';
$conf['reverse_proxy_addresses'] = {{data.reverse_proxy_addresses}};

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
$conf['omit_vary_cookie'] = {{data.omit_vary_cookie}};
// Do not use the new image style token. it removes images from varnish and
// breaks some modules
$conf['image_allow_insecure_derivatives'] = {{ data.image_allow_insecure_derivatives }};

// reduce uneeded queries by increasing the allowed max size of cached sentences (default is 75)
$conf['locale_cache_length'] = {{ data.locale_cache_length }}; //204800;
// Imagecache
$conf['image_jpeg_quality'] = {{ data.image_jpeg_quality}}; //95;

// CRON ///////////////////////////////////////////////////////////////
// disallow the poor-man cron, we do it via drush
$conf['cron_safe_threshold'] = 0;
// do not limit time for cron tasks
$conf['elysia_cron_time_limit'] = 0;

{% if data.smtp.used %}
// SMTP ///////////////////////////////////////////////////////////////
$conf['smtp_on'] = 1;
$conf['smtp_host'] = "{{ data.smtp.host }}";
$conf['smtp_from'] = "{{ data.smtp.from }}";
$conf['smtp_fromname'] = "{{ data.smtp.fromname }}";
{% endif %}

// File system ////////////////////////////////////////////////////////////////
// Warning: when PHP-FPM is chrooted, we musn't use real absolute path but only
// "absolute path in the choot"
$conf['file_directory_path'] = 'sites/default/files';
$conf['file_public_path'] = $conf['file_directory_path'];
# www/sites/default/settings.php
$root = dirname(dirname(dirname(dirname(__FILE__))));
$conf['file_private_path'] = $root . '/var/private';
$conf['file_temporary_path'] = $root . '/var/tmp';
$conf['file_directory_temp'] = $conf['file_temporary_path'];

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
$conf['file_chmod_directory']={{data.file_chmod_directory}};
// default is 0664
$conf['file_chmod_file']={{data.file_chmod_file}};
    ;
// ensure nothing in the default multithread shared umask will break
// our mkdir commands (chmod is not impacted, but mkdir is...)
umask(0000);


// default contact mail
$conf['site_mail'] = '{{ data.site_email }}';

// Pure performance: avoid banned ip query during bootstrap.
$conf['blocked_ips'] = array();

// Log level //////////////////////////////////////////////////////////////////
// 1 means some errors get to the end user, 2 means all errors, 0 none.
$conf['error_level'] = {{ data.error_level }};

// Compression ////////////////////////////////////////////////////////////////
// If compression is done on HTTPD level NEVER SET THIS to 1!
$conf['page_compression'] = {{ data.page_compression }};
// Generate aggregates
$conf['preprocess_css'] = {{ data.preprocess_css }};
$conf['preprocess_js'] =  {{ data.preprocess_js }};
// Generate gzip version of aggregates
$conf['js_gzip_compression'] = {{ data.js_gzip_compression }};
$conf['css_gzip_compression'] = {{ data.css_gzip_compression }};

// Define Drupal cache settings:--------------
// this is the key of anonymous cached page headers generations
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


$localsettingsfile = DRUPAL_ROOT . "/sites/default/local.settings.php";
if (file_exists($localsettingsfile)) {
 include_once($localsettingsfile);
}
