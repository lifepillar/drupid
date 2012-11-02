# coding: utf-8
require 'rubygems' if RUBY_VERSION < "1.9"
require 'bundler/setup'
require 'rake/testtask'
begin; require 'rdoc/task'; rescue LoadError; end

Rake::TestTask.new do |t|
  t.ruby_opts = ['-w'] # Turn warnings on
  t.libs << 'test'
# t.test_files = FileList['test/test_drupid_extend_pathname.rb']
  t.verbose = false
end

# Documentation
begin
RDoc::Task.new(:rdoc => "doc", :clobber_rdoc => "doc:clean", :rerdoc => "doc:force") do |rd|
  rd.rdoc_dir = 'doc'
  #rd.main = 'README.rdoc'
  #rd.rdoc_files.include('README.rdoc', 'lib/drupid.rb')
  rd.rdoc_files.include('lib/**/*.rb')
  rd.title = 'Drupid'
end
rescue
end

desc "Run tests"
task :default => :test
