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

class TestDrupidPatch < MiniTest::Unit::TestCase

  def setup
    @temp_dir = FIXTURES + 'templib'
    @temp_dir.mkpath
    (TESTSITE+'sites/all/modules/views').ditto @temp_dir+'views'
    @views = @temp_dir+'views'
  end

  def teardown
    @temp_dir.rmtree
  end

  def test_apply_patch
    assert((@views.exist? and @views.directory?), 'Temporary views dir not created')
    patch = Drupid::Patch.new "file://#{FIXTURES+'views-info.diff'}", 'test patch'
    assert_equal "file://#{FIXTURES+'views-info.diff'}", patch.url, 'Incorrect patch url'
    @temp_dir.cd do
      patch.fetch
    end
    assert_equal @temp_dir+'views-info.diff', patch.cached_location, 'Wrong cached location'
    assert((@temp_dir+'views-info.diff').exist?, 'Patch not downloaded')
    @views.cd do
      res = patch.apply
      assert res, 'Patch not applied'
    end
  end

end # TestDrupidPatch
