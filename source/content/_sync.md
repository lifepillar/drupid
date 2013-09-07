## Synchronization

<i class="icon-tint icon-large"></i> The most fundamental Drupid command is

    drupid -s mysite.make -p mysite
    
where `mysite.make` is a Drush makefile and `mysite` is the path to a Drupal site. Drupid compares the current status of `mysite` with its specification (the makefile) and tries to fix all the differences. Drupid can:

- <i class="icon-li icon-ok"></i> download and install missing projects and libraries;
- <i class="icon-li icon-ok"></i> update projects and libraries, including Drupal core;
- <i class="icon-li icon-ok"></i> **resolve all project dependencies**;
- <i class="icon-li icon-ok"></i> apply patches;
- <i class="icon-li icon-ok"></i> move projects to a different directory;
- <i class="icon-li icon-ok"></i> verify the integrity of the code.
- <i class="icon-li icon-ok"></i> delete unused projects and libraries.

Drupid always _preflights_ all the changes that should be applied so that, if a problem occurs, your site is not modified in any way.

Most important options:

- `-c`, `--no-core`: do not synchronize Drupal core.
- `-d`, `--no-deps`: do not automatically follow dependencies.
- `-l`, `--no-libs`: do not synchronize external libraries.
- `-n`, `--dry`: preflight changes, but do not apply them.
- `-f`, `--force`: apply changes even if there are errors.
- `-S`, `--site`: (for multisite platforms) specify the site to be synchronized.
- `-u`, `--updatedb`: update the site's database after a successful synchronization. This option requires Drush to be installed to take effect.
    
Note that Drupid can also be used to build Drupal platforms from scratch: just pass to `-p` a non-existing path.
