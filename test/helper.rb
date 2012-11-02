# -*- coding: utf-8 -*-
require 'rubygems' if RUBY_VERSION < "1.9"
require 'bundler/setup'
require 'minitest/unit'
#gem 'minitest' # Force using the gem instead of ruby 1.9's minitest
require 'drupid'

# The following is to turn off a warning (instance variable @colorize not initialized)
# which silence_warnings does not suppress.
module Turn
  module Colorize
    @colorize = nil
  end
end

silence_warnings do
  begin; require 'turn'; rescue LoadError; end
end

FIXTURES = Pathname.new(__FILE__).realpath.dirname + 'fixtures'
TESTSITE = FIXTURES + 'drupal-fake-site'

MiniTest::Unit.autorun
