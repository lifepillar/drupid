# -*- coding: utf-8 -*-

# Copyright (c) 2012 Lifepillar
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

class TestDrupidCache < MiniTest::Unit::TestCase

  def setup
    @cache = FIXTURES+'temp-cache'
    @cache.mkpath
  end

  def teardown
    @cache.rmtree
  end

  def test_cache_path
    assert_respond_to Drupid, 'cache_path'
    assert_respond_to Drupid, 'cache_path='
    Drupid.cache_path = @cache
    assert_equal @cache, Drupid.cache_path
  end

end # TestDrupidCache


class TestDrupidComponent < MiniTest::Unit::TestCase

  def test_create_component
    mc = Drupid::Component.new 'MyComponent'
    assert_equal 'MyComponent', mc.name, 'Wrong name'
    refute_respond_to mc, 'proj_type', 'proj_type should not be a method of Drupid::Component'
    assert_nil mc.local_path, 'Local path should be nil'
    assert_nil mc.download_url, 'Url should be nil'
    assert_nil mc.download_type, 'Download type should be nil'
    assert_instance_of Hash, mc.download_specs, 'Download specs should be a hash'
    refute mc.overwrite, 'Overwrite should be false'
    assert_instance_of Pathname, mc.subdir
    assert_equal '.', mc.subdir.to_s, 'Subdir should be the current directory by default'
    assert_equal mc.name, mc.directory_name, 'Directory name should be equal to the name'
    assert_respond_to mc, 'download_url=', 'Url should be mutable'
    assert_respond_to mc, 'download_type=', 'Download strategy should be mutable'
    assert_respond_to mc, 'subdir=', 'Subdir should be mutable'
    assert_respond_to mc, 'directory_name=', 'Directory name should be mutable'
    assert_respond_to mc, 'local_path=', 'Local path should be mutable'
    assert_equal mc.name, mc.extended_name, 'Extended name should be equal to name'
    refute mc.exist?, 'Component should not be cached'
    refute mc.patched?, 'Component should not be patched'
    refute mc.has_patches?, 'Component should not have patches'
  end

  def test_default_cache_paths
    mc = Drupid::Component.new 'MyComponent'
    assert_instance_of Pathname, mc.cached_location
    assert_instance_of Pathname, mc.patched_location
    assert_equal Drupid.cache_path+'Component/MyComponent/default/MyComponent', mc.cached_location
    assert_equal Drupid.cache_path+'Component/MyComponent/default/__patches/MyComponent', mc.patched_location
  end

  def test_add_patch
    c = Drupid::Component.new 'MyComponent'
    refute c.has_patches?
    c.add_patch('http://foo/bar/my.patch', 'just a patch')
    assert c.has_patches?
    n = 0
    c.each_patch do |p|
      n = n + 1
      assert_instance_of Drupid::Patch, p
      assert_equal 'http://foo/bar/my.patch', p.url
    end
    assert_equal 1, n, "Wrong number of patches"
  end

end # TestDrupidComponent

class TestDrupidComponentFetchAndPatch < MiniTest::Unit::TestCase

  def setup
    @cache = FIXTURES+'temp-cache'
    @cache.mkpath
    @old_cache_path = Drupid.cache_path
    Drupid.cache_path = @cache
  end

  def teardown
    Drupid.cache_path = @old_cache_path
    @cache.rmtree
  end

  def test_fetch_tar_gz
    c = Drupid::Component.new 'FooComponent'
    c.download_url = 'file://' + (FIXTURES+'views.tar.gz').to_s
    assert_instance_of String, c.download_url
    c.fetch
    assert c.local_path.exist?
    assert c.local_path.directory?
    assert_equal c.cached_location, c.local_path
  end

end # TestDrupidComponentFetchAndPatch

