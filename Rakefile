# -*- encoding: utf-8 -*-
require 'bundler/gem_tasks'
require 'rake/testtask'
begin; require 'rdoc/task'; rescue LoadError; end

Rake::TestTask.new do |t|
  t.verbose = false
  t.warning = false # Set to true to turn on warnings *and* set $VERBOSE = true
  t.libs << 'test'
  t.pattern = 'test/**/test_*.rb'
end

# Documentation
begin
RDoc::Task.new(:rdoc => "doc", :clobber_rdoc => "doc:clean", :rerdoc => "doc:force") do |rd|
  rd.rdoc_dir = 'doc'
  rd.main = 'README.md'
  rd.rdoc_files.include('README.md')
  rd.rdoc_files.include('lib/**/*.rb')
  rd.title = 'Drupid'
end
rescue
end

desc "Run tests"
task :default => :test
