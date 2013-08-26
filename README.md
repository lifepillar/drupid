## Drupid

The not-so-smart Drupal updater that keeps your Drupal platform in sync with a Drush makefile!

[![Gem Version](https://badge.fury.io/rb/drupid.png)](http://badge.fury.io/rb/drupid)

### How to run the tests

To run the whole test suite:

    bundle exec rake test

To run a single test file:

    bundle exec turn -Itest -Ilib test/test_<name>.rb

To run a single test:

    bundle exec turn -Itest -Ilib test/test_NAME.rb --name '<test method name>'
