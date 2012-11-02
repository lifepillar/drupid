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

class TestDrupidPlatformProject < MiniTest::Unit::TestCase

  def setup
    @platform = Drupid::Platform.new(TESTSITE)
  end

  def test_platform_project_creation
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'sites/all/modules/entity')
    assert_instance_of Drupid::PlatformProject, p
    assert_kind_of Drupid::Project, p
    assert_kind_of Drupid::Component, p
    assert_equal 'entity', p.name
    assert_equal 7, p.core.to_i
    assert_equal '7.x-1.0-rc1', p.version.long
    assert_equal 'module', p.proj_type
    assert_equal @platform, p.platform
  end

  def test_relative_path
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'sites/all/modules/entity')
    assert_instance_of Pathname, p.relative_path
    assert_equal 'sites/all/modules/entity', p.relative_path.to_s
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'sites/all/modules/subdir/ctools')
    assert_instance_of Pathname, p.relative_path
    assert_equal 'sites/all/modules/subdir/ctools', p.relative_path.to_s
  end

  def test_subdir
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'sites/all/modules/entity')
    assert_instance_of Pathname, p.subdir
    assert_equal '.', p.subdir.to_s
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'sites/all/modules/subdir/ctools')
    assert_instance_of Pathname, p.subdir
    assert_equal 'subdir', p.subdir.to_s
  end

  def test_core_project_color
    module_path = @platform.local_path+'modules/color'
    p = Drupid::PlatformProject.new(@platform, module_path)
    assert_equal 'color', p.name
    assert p.core_project?, 'color should be a core project'
    assert_equal '7.x-7.10', p.version.long
    assert_equal 'module', p.proj_type
  end

  def test_project_featured_news_feature
    module_path = @platform.local_path+'sites/all/modules/featured_news_feature'
    p = Drupid::PlatformProject.new(@platform, module_path)
    assert_equal 'featured_news_feature', p.name
    refute p.core_project?, 'featured_news_feature is not a core project'
    assert_equal '7.x-1.0', p.version.long
    assert_equal 'module', p.proj_type
    info_path = @platform.local_path+'sites/all/modules/featured_news_feature/featured_news.info'
    p = Drupid::PlatformProject.new(@platform, info_path)
    assert_equal 'featured_news_feature', p.name
    refute p.core_project?, 'featured_news_feature is not a core project'
    assert_equal '7.x-1.0', p.version.long
    assert_equal 'module', p.proj_type
  end

  def test_project_google_analytics
    module_path = @platform.local_path+'sites/all/modules/google_analytics'
    p = Drupid::PlatformProject.new(@platform, module_path)
    assert_equal 'google_analytics', p.name
    refute p.core_project?, 'google_analytics is not a core project'
    assert_equal '7.x-1.2', p.version.long
    assert_equal 'module', p.proj_type
    info_path = @platform.local_path+'sites/all/modules/google_analytics/googleanalytics.info'
    p = Drupid::PlatformProject.new(@platform, info_path)
    assert_equal 'google_analytics', p.name
    refute p.core_project?, 'google_analytics is not a core project'
    assert_equal '7.x-1.2', p.version.long
    assert_equal 'module', p.proj_type

  end

  def test_project_entity
    module_path = @platform.local_path+'sites/all/modules/entity'
    p = Drupid::PlatformProject.new(@platform, module_path)
    assert_equal 'entity', p.name
    refute p.core_project?, 'entity is not a core project'
    assert_equal '7.x-1.0-rc1', p.version.long
    assert_equal 'module', p.proj_type
    info_path = @platform.local_path+'sites/all/modules/entity/entity.info'
    p = Drupid::PlatformProject.new(@platform, info_path)
    assert_equal 'entity', p.name
    refute p.core_project?, 'entity is not a core project'
    assert_equal '7.x-1.0-rc1', p.version.long
    assert_equal 'module', p.proj_type
  end

  def test_project_entity_token
    info_path = @platform.local_path+'sites/all/modules/entity/entity_token.info'
    p = Drupid::PlatformProject.new(@platform, info_path)
    assert_equal 'entity_token', p.name
    refute p.core_project?, 'entity_token is not a core project'
    assert_equal '7.x-1.0-rc1', p.version.long
    assert_equal 'module', p.proj_type
  end

  def test_extensions_for_entity_project
    info_path = @platform.local_path+'sites/all/modules/entity/entity.info'
    p = Drupid::PlatformProject.new(@platform, info_path)
    exts = p.extensions
    assert_equal 4, exts.size
    assert exts.include?('entity')
    assert exts.include?('entity_token')
    assert exts.include?('entity_feature')
    assert exts.include?('entity_test')
  end

  def test_project_mothership
    info_path = @platform.local_path+'sites/all/themes/subdir/mothership/mothership/mothership.info'
    p = Drupid::PlatformProject.new(@platform, info_path)
    refute p.core_project?, 'mothership is not a core project'
    assert_equal info_path.parent.parent, p.local_path
    assert_equal '7.x-2.2', p.version.long
    assert_equal 'theme', p.proj_type
    exts = p.extensions
    assert_equal 4, exts.size
    assert exts.include?('mothership')
    assert exts.include?('mothershipstark')
    assert exts.include?('NEWTHEME')
    assert exts.include?('tema')
    assert_equal 'sites/all/themes/subdir/mothership', p.relative_path.to_s
    assert_equal 'subdir', p.subdir.to_s
  end

  def test_project_fusion
    info_path = @platform.local_path+'sites/all/themes/fusion'
    p = Drupid::PlatformProject.new(@platform, info_path)
    assert_equal info_path, p.local_path
    assert_equal 'fusion', p.name
    assert_equal '7.x-2.0-beta2', p.version.long
    assert_equal 'theme', p.proj_type
    exts = p.extensions
    assert_equal 4, exts.size
    assert exts.include?('fusion')
    assert exts.include?('fusion_core')
    assert exts.include?('fusion_starter')
    assert exts.include?('fusion_starter_lite')
    assert_equal 'sites/all/themes/fusion', p.relative_path.to_s
    assert_equal 'sites/all/themes/fusion', @platform.dest_path(p).to_s
  end

  def test_subproject_node_tests
    info_path = @platform.local_path+'modules/node/tests/node_access_test.info'
    p = Drupid::PlatformProject.new(@platform, info_path)
    assert p.core_project?
    assert_equal 'module', p.proj_type
    assert_equal 'node_access_test', p.name
    assert_equal info_path.parent, p.local_path
    assert_equal 'tests', p.directory_name
    assert_equal 'modules/node/tests', p.relative_path.to_s
    assert_equal 'node', p.subdir.to_s
  end

  # For a platform project, the target path should be a suffix of the
  # platform path. If that is not the case, it probably means that the
  # project is misplaced (e.g., a module in the 'themes' folder).
  def test_target_path_is_consistent_with_local_path
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'sites/all/modules/entity')
    assert p.local_path.fnmatch('*' + p.target_path.to_s), "Wrong target_path: #{p.target_path}"
    assert_equal @platform.local_path+@platform.contrib_path+p.target_path, p.local_path
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'sites/all/modules/featured_news_feature')
    assert p.local_path.fnmatch('*' + p.target_path.to_s), "Wrong target_path: #{p.target_path}"
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'sites/all/modules/google_analytics')
    assert p.local_path.fnmatch('*' + p.target_path.to_s), "Wrong target_path: #{p.target_path}"
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'sites/all/modules/entity/entity_token.info')
    assert p.local_path.fnmatch('*' + p.target_path.to_s), "Wrong target_path: #{p.target_path}"
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'sites/all/themes/subdir/mothership/mothership/mothership.info')
    assert p.local_path.fnmatch('*' + p.target_path.to_s), "Wrong target_path: #{p.target_path}"
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'profiles/openpublic/openpublic.info')
    assert_equal '.', p.subdir.to_s
    assert_equal 'profiles/openpublic', p.target_path.to_s
    assert p.local_path.fnmatch('*' + p.target_path.to_s), "Wrong target_path: #{p.target_path}"
    p = Drupid::PlatformProject.new(@platform, TESTSITE+'profiles/standard')
    assert_equal 'profiles/standard', p.target_path.to_s
    assert p.local_path.fnmatch('*' + p.target_path.to_s), "Wrong target_path: #{p.target_path} vs #{p.local_path}"
  end

end # TestDrupidPlatformProject
