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

class TestPathname < MiniTest::Unit::TestCase

  def setup
    @temp_dir = FIXTURES + 'templib'
    @temp_dir.mkpath
  end

  def teardown
    @temp_dir.rmtree
  end

  def test_ditto_src_file_dst_dir
    file = FIXTURES+'drupal-example.make'
    dst = file.ditto @temp_dir
    assert_instance_of Pathname, dst
    assert dst.exist?
    assert dst.file?
    assert_equal 'drupal-example.make', dst.basename.to_s
    assert_equal @temp_dir, dst.parent
  end

  def test_ditto_src_file_dst_file
    file = FIXTURES+'drupal-example.make'
    dst = file.ditto @temp_dir+'drupal-example-copy.make'
    assert_instance_of Pathname, dst
    assert dst.exist?
    assert dst.file?
    assert_equal 'drupal-example-copy.make', dst.basename.to_s
    assert_equal @temp_dir, dst.parent    
  end

  def test_ditto_src_dir_dst_dir
    dir = TESTSITE+'modules/aggregator'
    dst = dir.ditto @temp_dir
    assert_instance_of Pathname, dst
    assert dst.exist?
    assert dst.directory?
    assert_equal @temp_dir, dst
    assert((dst+'aggregator.info').exist?)
    assert((dst+'tests').directory?)
  end

end # TestPathname
