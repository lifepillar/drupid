## Drupid

_The not-so-smart Drupal updater that keeps your Drupal platform in sync with a Drush makefile!_

Drupid is a better replacement for [Drush](https://github.com/drush-ops/drush) `make`. Drupid does not only build a Drupal platform based on a makefile: it **synchronizes** a Drupal's platform with a makefile!

[![Gem Version](https://badge.fury.io/rb/drupid.png)](http://badge.fury.io/rb/drupid)


### Release Notes ###

#### Version 1.1.1 (2013/9/1) ####

Clean up the gem packaging process and fix a broken dependency in Ruby 1.8.

#### Version 1.1.0 (2013/9/1) ####

- Drush is no more a required dependency. Drush is now used only for database-related operations, but Drupid will work even if Drush is not found. When Drush is not installed, downgrading a project always requires `--force`.
- Added a `--updatedb` option to automatically update Drupal's database after a successful synchronization. If Drush is not installed, this option has no effect.
- The logic of choosing the best candidate for an update has been changed. Instead of relying on Drush's “recommended” and “supported” releases, Drupid now implements its own method. In general, Drupid will always prefer stable releases (whose version does not contain any extra part) over anything else. So, for example, if a project has version 1.1 and version 2.0-rc1, Drupid will consider 1.1 better (i.e., more stable) than 2.0-rc1, even if 2.0-rc1 is the recommended release. One can always choose a specific version in the makefile, of course. See `Drupid::Version#better` for the details.
- Overall improvement of Drupid's output messages.
- Fixed bugs in parsing Drush output by using the YAML format (tested with Drush 6.0).
- Drupid should now always exit with exit code 1 upon failure.
- Lots of other bug fixes.


#### Version 1.0.2 (2013/8/26) ####

Tested compatibility with Ruby 2.0.

#### Version 1.0.1 (2012/11/5) ####

Fixed a bug causing a “Can't convert Pathname to String” error in some Ruby variants (e.g., 1.9.1-p243).

#### Version 1.0.0 ####

First public release.


### How To Run The Tests ###

To run the whole test suite:

    bundle exec rake test

To run a single test file:

    bundle exec ruby -Itest -Ilib test/test_<name>.rb

or

    bundle exec rake test TEST='test/test_<name>.rb'

To run a single test:

    ruby -Itest -Ilib test/test_NAME.rb --name '<test method name>'
