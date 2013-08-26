## Drupid

The not-so-smart Drupal updater that keeps your Drupal platform in sync with a Drush makefile!

[![Gem Version](https://badge.fury.io/rb/drupid.png)](http://badge.fury.io/rb/drupid)


### Release Notes

#### Version 1.0.2 (2013/8/26)

Tested compatibility with Ruby 2.0.

#### Version 1.0.1 (2012/11/5)

Fix a bug causing a “Can't convert Pathname to String” error in some Ruby variants (e.g., 1.9.1-p243).

#### Version 1.0.0

First public release.


### How To Run The Tests

To run the whole test suite:

    bundle exec rake test

To run a single test file:

    bundle exec turn -Itest -Ilib test/test_<name>.rb

To run a single test:

    bundle exec turn -Itest -Ilib test/test_NAME.rb --name '<test method name>'
