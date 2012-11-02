core = 7.x
api = 2
projects[drupal][version] = 7.8

projects[jquery_ui][subdir] = contrib

libraries[profiler][download][type] = "get"
libraries[profiler][download][url] = "http://ftp.drupal.org/files/projects/profiler-7.x-2.0-beta1.tar.gz"

libraries[jquery_ui][download][type] = "file"
libraries[jquery_ui][download][url] = "http://jquery-ui.googlecode.com/files/jquery.ui-1.6.zip"
libraries[jquery_ui][download][md5] = "c177d38bc7af59d696b2efd7dda5c605"
libraries[jquery_ui][destination] = "modules/contrib/jquery_ui"

libraries[shadowbox][download][type] = "post"
libraries[shadowbox][download][post_data] = "format=tar&adapter=jquery&players[]=img&players[]=iframe&players[]=html&players[]=swf&players[]=flv&players[]=qt&players[]=wmp&language=en&css_support=on"
libraries[shadowbox][download][file_type] = "tar.gz"
libraries[shadowbox][download][url] = "http://www.shadowbox-js.com/download"
libraries[shadowbox][directory_name] = "shadowbox"
libraries[shadowbox][destination] = "libraries"
