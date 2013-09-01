# -*- coding: utf-8 -*-
require 'bundler/setup'
require 'minitest/autorun'
require 'drupid'

FIXTURES = Pathname.new(__FILE__).realpath.dirname + 'fixtures'
TESTSITE = FIXTURES + 'drupal-fake-site'
