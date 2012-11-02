core = 7.x
api = 2
version = "7.x-1.0"
projects[] = drupal

projects[] = views
projects[wysiwyg] = 2.1
projects[ctools][version] = 1.0-rc1
projects[tao][type] = theme
projects[tao][download][type] = git
projects[tao][download][url] = git://github.com/developmentseed/tao.git

libraries[profiler][download][type] = "get"
libraries[profiler][download][url] = "http://ftp.drupal.org/files/projects/profiler-7.x-2.0-beta1.tar.gz"
