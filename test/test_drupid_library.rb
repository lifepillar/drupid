# -*- coding: utf-8 -*-

# Copyright (c) 2012-2013 Lifepillar
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'helper'

class TestDrupidLibrary < MiniTest::Unit::TestCase

  def test_create_library
    ml = Drupid::Library.new 'MyLibrary'
    assert_equal 'MyLibrary', ml.name, 'Wrong name'
    assert_equal 'file', ml.download_type, 'Default download type should be \'file\''
    assert_equal ml.name, ml.directory_name
    assert_instance_of Pathname, ml.subdir
    assert_equal '.', ml.subdir.to_s
    assert_instance_of Pathname, ml.destination, 'Destination should be a Pathname'
    assert_equal 'libraries', ml.destination.to_s, 'Destination should be \'libraries\''
    assert_respond_to ml, 'directory_name=', 'Directory name should be mutable'
    assert_respond_to ml, 'subdir=', 'Subdir should be mutable'
    assert_respond_to ml, 'destination=', 'Destination should be mutable'
  end

  def test_cached_paths
    ml = Drupid::Library.new 'MyLibrary'
    assert_equal Drupid.cache_path+'Library/MyLibrary/file/MyLibrary', ml.cached_location
    assert_equal Drupid.cache_path+'Library/MyLibrary/file/__patches/MyLibrary', ml.patched_location
  end

  def test_target_path
    l = Drupid::Library.new 'MyLibrary'
    assert_instance_of Pathname, l.target_path
    assert_equal 'libraries/MyLibrary', l.target_path.to_s
    l.subdir = 'contrib'
    assert_instance_of Pathname, l.target_path
    assert_equal 'libraries/contrib/MyLibrary', l.target_path.to_s
    l.destination = 'modules/mymodule'
    assert_instance_of Pathname, l.target_path
    assert_equal 'modules/mymodule/contrib/MyLibrary', l.target_path.to_s
    l.directory_name = 'my_library'
    assert_instance_of Pathname, l.target_path
    assert_equal 'modules/mymodule/contrib/my_library', l.target_path.to_s
  end

end # TestDrupidLibrary
