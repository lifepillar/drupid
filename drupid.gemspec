# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'drupid/version'

Gem::Specification.new do |gem|
  gem.name          = 'drupid'
  gem.version       = Drupid::VERSION
  gem.license     = 'MIT'
  gem.authors       = ['Lifepillar']
  gem.email         = 'lifepillar@lifepillar.com'
  gem.description   = 'Drupid keeps a Drush makefile in sync with a Drupal distribution.'
  gem.summary       = 'The not-so-smart Drupal bundler!'
  gem.date          = Time.now.strftime('%Y-%m-%d')
  gem.homepage      = 'http://lifepillar.com'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
  gem.has_rdoc      = true
  gem.rdoc_options << '--title' << 'Drupid' << '--main' << 'README.rdoc' <<
                      'line-numbers'

  # Dependencies
  gem.add_runtime_dependency 'rgl', ['>= 0.4.0']
  nokogiri_version = (RUBY_VERSION < '1.9') ? '= 1.5.9' : '>= 1.6.0'
  gem.add_runtime_dependency 'nokogiri', [nokogiri_version]
  gem.add_development_dependency 'minitest', ['>= 5.0.6']
  gem.add_development_dependency 'rdoc', ['>= 0']
end
