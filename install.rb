#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

puts "Installing with Ruby #{%x[rbenv version]}"
o = %x[gem build drupid.gemspec]
puts o
f = o.match(/File:(.+)$/)[1].strip
system 'gem', 'install', "./#{f}", '--no-ri', '--no-rdoc'
