# -*- coding: utf-8 -*-
require 'rake'
require 'pathname'

v = (Pathname.new(__FILE__).parent + 'lib/drupid.rb').open("r").read.match(/DRUPID_VERSION.+'(.+)'/)[1]

Gem::Specification.new do |s|
  s.name        = 'drupid'
  s.version     = v
  s.date        = Time.now.strftime("%Y-%m-%d")
  s.summary     = "The not-so-smart Drupal bundler!"
  s.description = "Drupid keeps a Drush makefile in sync with a Drupal distribution."
  s.authors     = ["Lifepillar"]
  s.email       = 'lifepillar@lifepillar.com'
  s.files       = FileList['lib/**/*.rb', 'bin/drupid'].to_a
  s.executables << 'drupid'
  s.add_runtime_dependency "rgl", [">= 0.4.0"]
  s.homepage    = 'http://lifepillar.com'
  s.license     = 'MIT'
end
