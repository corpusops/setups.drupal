; API Version is here just to avoid warning message
api = 2

; We are in Drupal 7
core = 7.x
projects[drupal][type] = core

; Makina Corpus basis of the site
projects[] = entity
projects[] = ctools
projects[] = views
projects[] = entityreference

; Box
projects[] = colorbox
libraries[colorbox][download][type] = "get"
libraries[colorbox][download][url] = "https://github.com/jackmoore/colorbox/archive/1.x.zip"
libraries[colorbox][directory_name] = "colorbox"
libraries[colorbox][destination] = "libraries"

; Themes
; Base theme 
; Beware: Bootstrap 3.1 version will require PHP 5.3 and jQuery 1.9+
projects[] = bootstrap
libraries[bootstrap][download][type] = "get"
libraries[bootstrap][download][url] = "https://github.com/twbs/bootstrap/archive/v3.0.3.zip"
libraries[bootstrap][directory_name] = "bootstrap"
libraries[bootstrap][destination] = "themes/bootstrap"
libraries[bootstrap][overwrite] = TRUE
