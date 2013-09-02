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

class TestDrupidVersion < Minitest::Test

  def test_version_object_creation
    v = Drupid::Version.new(7, '1.0-rc4')
    assert_instance_of Drupid::VersionCore, v.core, 'Core version should be a Drupid::VersionCore object'
    assert_equal '7.x', v.core.to_s
    assert_equal 7, v.core.to_i
    assert_equal 1, v.major
    assert_equal 0, v.patchlevel
    assert_equal 'rc4', v.extra
    assert_equal '1.0-rc4', v.short
    assert_equal '7.x-1.0-rc4', v.long
    v = Drupid::Version.new(7, '1.0-unstable5')
    assert_equal 7, v.core.to_i
    assert_equal 1, v.major
    assert_equal 0, v.patchlevel
    assert_equal Drupid::Version::UNSTABLE, v.extra_type
    assert_equal 5, v.extra_num
    assert_equal 'unstable5', v.extra
    assert_equal '1.0-unstable5', v.short
    assert_equal '7.x-1.0-unstable5', v.long
  end

  def test_damned_drupal_dev_version
    # Yes, projects typically (always?) have NUM.x-dev, but Drupal has NUM.NUM-dev...
    v = Drupid::Version.new(7, '7.24-dev')
    assert_equal '7.x', v.core.to_s
    assert_equal 7, v.major
    assert_equal 24, v.patchlevel
    assert_equal 'dev', v.extra
    assert_equal '7.24-dev', v.short
    assert_equal '7.x-7.24-dev', v.long
  end

  def test_core
    core = Drupid::VersionCore.new '8.x'
    assert_equal 8, core.to_i
    assert_equal '8.x', core.to_s
    core = Drupid::VersionCore.new '8'
    assert_equal 8, core.to_i
    assert_equal '8.x', core.to_s
    core = Drupid::VersionCore.new '8.x-1.0'
    assert_equal 8, core.to_i
    assert_equal '8.x', core.to_s
    core = Drupid::VersionCore.new 8
    assert_equal 8, core.to_i
    assert_equal '8.x', core.to_s
    core = Drupid::VersionCore.new(Drupid::Version.new(8, '1.0'))
    assert_equal 8, core.to_i
    assert_equal '8.x', core.to_s
    core2 = Drupid::VersionCore.new core
    assert_equal 8, core2.to_i
    assert_equal '8.x', core2.to_s
    assert_raises Drupid::NotDrupalVersionError do
      # We do not accept this as it is not distinguishable
      # from a short project version.
      core = Drupid::VersionCore.new '8.0'
    end
  end

  def test_version_short_and_long
    v = Drupid::Version.new(8, '1.0-rc4')
    assert_instance_of Fixnum, v.major
    assert_equal 1, v.major
    assert_instance_of Fixnum, v.patchlevel
    assert_equal 0, v.patchlevel
    assert_instance_of Fixnum, v.extra_type
    assert_equal Drupid::Version::RC, v.extra_type
    assert_instance_of Fixnum, v.extra_num
    assert_equal 4, v.extra_num
    assert_equal '1.0-rc4', v.short
    assert_equal '8.x-1.0-rc4', v.long
    v = Drupid::Version.new(10, '17.123-unstable18')
    assert_equal '17.123-unstable18', v.short
    assert_equal '10.x-17.123-unstable18', v.long
    v = Drupid::Version.new(0, '1.x-dev23')
    assert_equal '1.x-dev23', v.short
    assert_equal '0.x-1.x-dev23', v.long
    v = Drupid::Version.new(8, '2.x-dev')
    assert_equal '2.x-dev', v.short
    assert_equal '8.x-2.x-dev', v.long
    v = Drupid::Version.new(8, '1.0')
    assert_equal '1.0', v.short
    assert_equal '8.x-1.0', v.long
  end

  def test_version_equality_comparison
    v1 = Drupid::Version.new(8, '1.0-rc2')
    v2 = Drupid::Version.new(8, '1.0')
    v3 = Drupid::Version.new(8, '1.0')
    v4 = Drupid::Version.new(9, '1.0')
    v5 = Drupid::Version.new(7, '1.0')
    assert_equal v2, v2, 'An object should be == to itself'
    assert_equal v2, v3, 'An object should be == to itself'
    assert_equal v3, v2, 'v2 and v3 should compare =='
    assert v1.eql?(v1), 'v1 should be eql? to itself'
    assert v2.eql?(v2), 'v2 should be eql? to itself'
    refute v2.eql?(v3), 'v2 should not be eql? to v3'
    refute v3.eql?(v2), 'v3 should not be eql? to v2'
    refute_equal v1, v2, "v1 (#{v1.to_s}) should not be == to v2 (#{v2.to_s})"
    refute_equal v2, v1, 'v2 should not be == to v1'
    refute_equal v3, v4, 'v3 should not be == to v4'
    refute_equal v3, v5, 'v3 should not be == to v5'
  end

  def test_less_than_comparison
    v1  = Drupid::Version.new(8, '1.0-unstable1')
    v2  = Drupid::Version.new(8, '1.0-unstable5')
    v3  = Drupid::Version.new(8, '1.0-alpha1')
    v4  = Drupid::Version.new(8, '1.0-alpha4')
    v5  = Drupid::Version.new(8, '1.0-beta1')
    v6  = Drupid::Version.new(8, '1.0-beta12')
    v7  = Drupid::Version.new(8, '1.0-rc1')
    v8  = Drupid::Version.new(8, '1.0-rc2')
    v9  = Drupid::Version.new(8, '1.0')
    v10 = Drupid::Version.new(8, '1.0')
    v11 = Drupid::Version.new(8, '1.1')
    v12 = Drupid::Version.new(8, '1.x-dev')
    v13 = Drupid::Version.new(8, '2.0')
    v14 = Drupid::Version.new(9, '2.0')
    v15 = Drupid::Version.new(7, '2.0')
    assert v1 < v2, 'v1 < v2'
    assert v2 < v3, 'v2 < v3'
    assert v3 < v4, 'v3 < v4'
    assert v4 < v5, 'v4 < v5'
    assert v5 < v6, 'v5 < v6'
    assert v6 < v7, 'v6 < v7'
    assert v7 < v8, 'v7 < v8'
    assert v8 < v9, 'v8 < v9'
    refute v9 < v10, 'v9 == v10'
    assert v10 < v11, 'v10 < v11'
    assert v12 < v11, 'v12 < v11'
    assert v12 < v13, 'v12 < v13'
    assert v13 < v14, 'v13 < v14'
    assert v15 < v13, 'v15 < v13'
    assert v12 < v1, 'v12 < v1'
  end

  def test_multiway_comparison
    v1  = Drupid::Version.new(8, '1.0-unstable1')
    v2  = Drupid::Version.new(8, '1.0-unstable5')
    v3  = Drupid::Version.new(8, '1.0-alpha1')
    v4  = Drupid::Version.new(8, '1.0-alpha4')
    v5  = Drupid::Version.new(8, '1.0-beta1')
    v6  = Drupid::Version.new(8, '1.0-beta12')
    v7  = Drupid::Version.new(8, '1.0-rc1')
    v8  = Drupid::Version.new(8, '1.0-rc2')
    v9  = Drupid::Version.new(8, '1.0')
    v10 = Drupid::Version.new(8, '1.0')
    v11 = Drupid::Version.new(8, '1.1')
    v12 = Drupid::Version.new(8, '1.x-dev')
    v13 = Drupid::Version.new(8, '2.0')
    v14 = Drupid::Version.new(9, '2.0')
    v15 = Drupid::Version.new(7, '2.0')

    assert_equal(-1, v1 <=> v2, 'v1 <=> v2')
    assert_equal(-1, v2 <=> v3, 'v2 <=> v3')
    assert_equal(-1, v3 <=> v4, 'v3 <=> v4')
    assert_equal(-1, v4 <=> v5, 'v4 <=> v5')
    assert_equal(-1, v5 <=> v6, 'v5 <=> v6')
    assert_equal(-1, v6 <=> v7, 'v6 <=> v7')
    assert_equal(-1, v7 <=> v8, 'v7 <=> v8')
    assert_equal(-1, v8 <=> v9, 'v8 <=> v9')
    assert_equal  0, v9 <=> v10, 'v9 <=> v10'
    assert_equal  0, v10 <=> v9, 'v10 <=> v9'
    assert_equal  0, v10 <=> v10, 'v10 <=> v10'
    assert_equal(-1, v10 <=> v11, 'v10 <=> v11')
    assert_equal( 1, v11 <=> v12, 'v11 <=> v12')
    assert_equal(-1, v12 <=> v1, 'v12 <=> v11')
    assert_equal(-1, v12 <=> v13, 'v12 <=> v13')
    assert_equal  1, v2 <=> v1
    assert_equal(-1, v13 <=> v14)
    assert_equal  1, v13 <=> v15
  end

  def test_version_from_string
    versions = ['8.x-1.0', '7.x-1.x-dev']
    versions.each do |vs|
      v = Drupid::Version.from_s vs
      assert_instance_of Drupid::Version, v, "Not a Drupid::Version object: #{vs}"
      assert_equal vs, v.long, "Wrong long version: #{vs}"
    end
  end

  def test_wrong_version_specification
    assert_raises Drupid::NotDrupalVersionError do
      Drupid::Version.from_s '1.0' # missing core number (e.g., '7.x-1.0')
    end
    assert_raises Drupid::NotDrupalVersionError do
      Drupid::Version.from_s '7.x'
    end
    assert_raises RuntimeError do
      Drupid::Version.new(7, 1.0)
    end
  end

  def test_version_extra
    v1  = Drupid::Version.new(8, '1.0-unstable1')
    v2  = Drupid::Version.new(8, '1.0-alpha4')
    v3  = Drupid::Version.new(8, '1.0-beta12')
    v4  = Drupid::Version.new(8, '1.0-rc2')
    v5  = Drupid::Version.new(8, '1.0')
    v6  = Drupid::Version.new(8, '1.x-dev')
    v7  = Drupid::Version.new(8, '8.x')
    refute v1.stable?, 'v1 is not stable'
    refute v2.stable?, 'v2 is not stable'
    refute v3.stable?, 'v3 is not stable'
    refute v4.stable?, 'v4 is not stable'
    assert v5.stable?, 'v5 is stable'
    refute v6.stable?, 'v6 is not stable'
    refute v7.stable?, 'v7 is not stable'
    refute v1.release_candidate?, 'v1 is not rc'
    refute v2.release_candidate?, 'v2 is not rc'
    refute v3.release_candidate?, 'v3 is not rc'
    assert v4.release_candidate?, 'v4 is rc'
    refute v5.release_candidate?, 'v5 is not rc'
    refute v6.release_candidate?, 'v6 is not rc'
    refute v7.release_candidate?, 'v7 is not rc'
    refute v1.alpha?, 'v1 is not alpha'
    assert v2.alpha?, 'v2 is alpha'
    refute v3.alpha?, 'v3 is not alpha'
    refute v4.alpha?, 'v4 is not alpha'
    refute v5.alpha?, 'v5 is not alpha'
    refute v6.alpha?, 'v6 is not alpha'
    refute v7.alpha?, 'v7 is not alpha'
    refute v1.beta?, 'v1 is not beta'
    refute v2.beta?, 'v2 is not beta'
    assert v3.beta?, 'v3 is beta'
    refute v4.beta?, 'v4 is not beta'
    refute v5.beta?, 'v5 is not beta'
    refute v6.beta?, 'v6 is not beta'
    refute v7.beta?, 'v7 is not beta'
    refute v1.development_snapshot?, 'v1 is not development snapshot'
    refute v2.development_snapshot?, 'v2 is not development snapshot'
    refute v3.development_snapshot?, 'v3 is not development snapshot'
    refute v4.development_snapshot?, 'v4 is not development snapshot'
    refute v5.development_snapshot?, 'v5 is not development snapshot'
    assert v6.development_snapshot?, 'v6 is not development snapshot'
    assert v7.development_snapshot?, 'v7 is not development snapshot'
  end

  def test_natural_ordering
    vv = ['0.x', '0.9-alpha4', '0.9-beta0', '0.9', '1.x-dev',
          '1.x-dev2', '1.0-unstable1', '1.0-alpha4', '1.0-alpha40',
          '1.0-beta1', '1.0-beta12', '1.0-rc1', '1.0-rc2', '1.0-rc21',
          '1.0', '1.1-dev', '1.1-beta1', '1.1', '2.x-dev']
    vv2 = vv.shuffle
    vv2.map! { |v| Drupid::Version.new(8, v) }
    vv2.sort!
    vv2.map! { |v| v.short }
    assert_equal vv, vv2, 'not sorted correctly'

    vv = ['1.x-dev', '1.x', '1.0-unstable6', '1.0-alpha4', '1.0-beta0',
          '1.0-rc1', '1.0', '2.x-dev']
    vv2 = vv.shuffle
    vv2.map! { |v| Drupid::Version.new(8, v) }
    vv2.sort!
    vv2.map! { |v| v.short }
    assert_equal vv, vv2, 'not sorted correctly'
  end

  def test_best_version
    vv = ['0.x', '1.x-dev', '1.x-dev2', '1.1-dev', '2.x-dev', '1.0-unstable1',
          '0.9-alpha4', '1.0-alpha4', '1.0-alpha40',
          '0.9-beta0', '1.0-beta1', '1.0-beta12', '1.1-beta1',
          '1.0-rc1', '1.0-rc2', '1.0-rc21', '0.9', '1.0', '1.1']
    vv2 = vv.shuffle
    vv2.map! { |v| Drupid::Version.new(7, v) }
    vv2.sort! { |a,b| a.better(b) }
    vv2.map! { |v| v.short }
    assert_equal vv, vv2, 'not sorted correctly'
  end

end # TestDrupidVersion
