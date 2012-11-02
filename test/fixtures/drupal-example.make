core = 7.x
api = 2
projects[drupal][version] = 7.8

; **Project with no further options:**
projects[] = views

; **Project using options (see below):**
projects[ctools][version] = 1.0-rc1

; Shorthand syntax for versions if no other options are to be specified:
projects[wysiwyg] = 2.1

; Place a project within a subdirectory of the `--contrib-destination` specified. 
projects[cck][subdir] = "contrib"

; URL of an alternate project update XML server to use:
projects[tao][location] = "http://code.developmentseed.com/fserver"

; The project type:
projects[tao][type] = theme

; Use an alternative download method instead of retrieval through update XML:
projects[tao][download][type] = git

; The URL of the repository (required):
projects[tao][download][url] = git://github.com/developmentseed/tao.git

projects[] = respond

; Provide an alternative directory name for this project:
;projects[mytheme][directory_name] = "yourtheme"

; Specific URL (can include tokens) to a translation:
;projects[mytheme][l10n_path] = "http://myl10nserver.com/files/translations/%project-%core-%version-%language.po"

; URL to an l10n server XML info file.
;projects[mytheme][l10n_url] = "http://myl10nserver.com/l10n_server.xml"

; Allows the project to be installed in a directory that is not empty.
;projects[myproject][overwrite] = TRUE

; Sometimes, drush (at least, up to 4.5) is not able to resolve
; dependencies. For example, the Calendar module depends on date_api and date_views,
; which are submodules of the Date module. Unfortunately, drush is not able
; to guess that. In such cases, the pre-requisites of a module must be included
; explicitly in the makefile:
projects[] = date

; Drupid does not support version constraints yet, but it should not break when it meets one.
projects[] = file_entity (>1.99)
projects[] = patterns(>0.1)
projects[] = "imce"(<10.0)
projects[] = "insert" (>2.0)

; Patches:
projects[calendar][patch][rfc-fixes][url] = "http://drupal.org/files/issues/cal-760316-rfc-fixes-2.diff"
projects[calendar][patch][rfc-fixes][md5] = "e4876228f449cb0c37ffa0f2142"

; shorthand syntax if no md5 checksum is specified
projects[jquery_ui][patch][] = "http://path/to/some-patch.diff"

; Local project
projects[foobar][download][url] = "mymodules/foobar.zip"

; An array of non-Drupal-specific libraries to be retrieved:
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

; Local library
libraries[foolib][download][url] = "foolib.tar.gz"

; An array of makefiles to include:
;includes[example] = "example.make"
;includes[example_relative] = "../example_relative/example_relative.make"
;includes[remote] = "http://www.example.com/remote.make"

