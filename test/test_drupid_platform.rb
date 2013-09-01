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

class TestDrupidPlatform < Minitest::Test


  def setup
    @platform = Drupid::Platform.new(TESTSITE)
    @num_projects = @platform.analyze_projects
  end

  def test_platform_properties
    assert_instance_of Pathname, @platform.local_path
    assert @platform.local_path.exist?
    assert_instance_of Pathname, @platform.sites_dir
    assert_equal 'sites', @platform.sites_dir.to_s
    assert_instance_of Pathname, @platform.contrib_path
    assert_equal 'sites/all', @platform.contrib_path.to_s
    assert_equal @platform.local_path + @platform.sites_dir, @platform.sites_path
    assert_instance_of Array, @platform.site_names
    assert_equal 3, @platform.site_names.size
    assert_includes @platform.site_names, 'default'
    assert_includes @platform.site_names, 'www.foo.org'
    assert_includes @platform.site_names, 'www.bar.org'
  end

  def test_contrib_path
    assert_equal 'sites/all', @platform.contrib_path.to_s
  end

  def test_dest_path
    components = {
      'views'  => 'sites/all/modules/views',
      'ctools' => 'sites/all/modules/subdir/ctools',
      'openpublic' => 'profiles/openpublic',
      'forum' => 'modules/forum',
      'bartik' => 'themes/bartik',
      'tao' => 'sites/all/themes/tao',
      'mothership' => 'sites/all/themes/subdir/mothership',
      'google_analytics' => 'sites/all/modules/google_analytics',
      'featured_news_feature' => 'sites/all/modules/featured_news_feature'
    }
    components.each do |name, path|
      comp = @platform.get_project(name)
      assert_instance_of Pathname, @platform.dest_path(name)
      assert_equal path, @platform.dest_path(name).to_s
      assert_equal path, @platform.dest_path(comp).to_s
    end
  end

  def test_profiles
    profiles = @platform.profiles
    assert_instance_of Array, profiles
    assert_equal 4, profiles.size
    assert profiles.include?('standard')
    assert profiles.include?('minimal')
    assert profiles.include?('testing')
    assert profiles.include?('openpublic')
  end

  def test_project_type
    assert_instance_of Drupid::PlatformProject, @platform.get_project('user')
    assert_equal 'module', @platform.get_project('user').proj_type, 'user project'
    assert_equal 'module', @platform.get_project('aggregator').proj_type, 'aggregator project'
    assert_equal 'module', @platform.get_project('list').proj_type, 'list (sub)project (of field)'
    assert_equal 'module', @platform.get_project('views').proj_type, 'views project'
    assert_equal 'module', @platform.get_project('ctools').proj_type, 'ctools project'
    assert_equal 'theme', @platform.get_project('bartik').proj_type, 'bartik theme'
    assert_equal 'theme', @platform.get_project('block_test_theme').proj_type, 'block_test_theme'
    assert_equal 'theme', @platform.get_project('tao').proj_type, 'tao theme'
    assert_equal 'theme', @platform.get_project('mothership').proj_type, 'mothership theme'
    assert_equal 'theme', @platform.get_project('mothershipstark').proj_type, 'mothershipstark (sub)theme'
    assert_equal 'profile', @platform.get_project('minimal').proj_type, 'minimal profile'
    assert_equal 'profile', @platform.get_project('standard').proj_type, 'standard profile'
    assert_equal 'profile', @platform.get_project('testing').proj_type, 'testing profile'
    assert_equal 'profile', @platform.get_project('openpublic').proj_type, 'openpublic profile'
  end

  def test_core_project
    assert @platform.get_project('user').core_project?
    assert @platform.get_project('aggregator').core_project?
    assert @platform.get_project('list').core_project?
    assert @platform.get_project('bartik').core_project?
    assert @platform.get_project('block_test_theme').core_project?
    assert @platform.get_project('minimal').core_project?
    assert @platform.get_project('standard').core_project?
    assert @platform.get_project('testing').core_project?
    refute @platform.get_project('views').core_project?
    refute @platform.get_project('ctools').core_project?
    refute @platform.get_project('tao').core_project?
    refute @platform.get_project('mothership').core_project?
    refute @platform.get_project('mothershipstark').core_project?
    refute @platform.get_project('openpublic').core_project?
  end

  def test_has_project
    assert_nil @platform.drupal_project
    assert_nil @platform.version
    assert @platform.has_project?('wysiwyg'), 'Platform should have wysiwyg'
    assert @platform.has_project?('ctools'), 'Platform should have ctools'
    refute @platform.has_project?('zigzag'), 'Platform should not have zigzag'
    assert @platform.has_project?('aggregator'), 'Platform should have aggregator'
  end

  def test_parse_projects
    num_info_files = Pathname.glob(@platform.local_path + '**/*.info').size
    # Modules and themes inside profiles should not be parsed
    excluded = Pathname.glob(@platform.local_path + 'profiles/*/*/**/*.info')
    # Projects whose name is different from the name of their parent directories should not be parsed
    #excluded2 = Dir[File.join(@platform.path, '**', '*.info')].reject { |p| File.basename(p, '.info') == File.basename(File.dirname(p)) }
    excluded2 = []
    assert_equal num_info_files - excluded.size - excluded2.size, @num_projects
    assert_instance_of Drupid::PlatformProject, @platform.get_project('wysiwyg'), 'wysiwyg should be a Drupid::PlatformProject'
    assert_instance_of Drupid::PlatformProject, @platform.get_project('node'), 'node should be a Drupid::PlatformProject'
    Pathname.glob(@platform.local_path + '**/*.info').reject { |p| excluded.include?(p) or excluded2.include?(p) }.each do |p|
      name = p.basename('.info').to_s
      # In some cases, the name of the .info file does not correspond to the project's name.
      # Why::Are::Drupal.specs.so_sloppy? :/
      name = 'google_analytics' if 'googleanalytics' == name
      name = 'featured_news_feature' if 'featured_news' == name
      assert @platform.has_project?(name), "#{name} not parsed."
      assert_instance_of Drupid::PlatformProject, @platform.get_project(name), "#{name} is not a Drupid::PlatformProject"
      if name != 'tao' # Tao has no version
        assert_instance_of Drupid::Version, @platform.get_project(name).version, "#{name} has not been assigned a version"
      end
    end
    assert_equal '7.x-1.0-rc1', @platform.get_project('ctools').version.long
    assert_nil @platform.get_project('tao').version
    assert_equal '7.x-7.10', @platform.get_project('minimal').version.long
    assert_equal '7.x-2.2', @platform.get_project('mothership').version.long
    refute @platform.has_project?('openpublic_splash'), 'openpublic_splash should not be parsed'
    refute @platform.has_project?('openomega'), 'openomega should not be parsed'
  end

  def test_is_core_project
    assert @platform.get_project('node').core_project?, 'node is a core project'
    assert @platform.get_project('field_sql_storage').core_project?, 'field_sql_storage is a core project'
    assert @platform.get_project('garland').core_project?, 'garland is a core project'
    refute @platform.get_project('wysiwyg').core_project?, 'wysiwyg is not a core project'
    refute @platform.get_project('ctools').core_project?, 'ctools is not a core project'
    refute @platform.get_project('tao').core_project?, 'tao is not a core project'
  end

  def test_each_project
    l = []
    @platform.each_project { |p| l << p.name }
    refute l.include?('drupal'), 'drupal should not be included'
    assert l.include?('ctools'), 'ctools missing'
    assert l.include?('wysiwyg'), 'wysiwyg missing'
  end

  def test_each_core_project
    l = []
    @platform.each_core_project { |p| l << p.name }
    refute l.include?('drupal')
    refute l.include?('ctools')
    refute l.include?('wysiwyg')
  end

  def test_project_names
    l = @platform.project_names
    refute l.include?('drupal'), 'drupal should not be included'
    assert l.include?('ctools'), 'ctools should be included'
    assert l.include?('wysiwyg'), 'wysiwyg should be included'
    refute l.include?('node')
    refute l.include?('menu')
  end

  def test_core_project_names
    l = @platform.core_project_names
    refute l.include?('drupal'), 'drupal should not be included'
    refute l.include?('ctools'), 'ctools is not core'
    refute l.include?('wysiwyg'), 'wysiwyg is not core'
    assert l.include?('node'), 'node is missing'
    assert l.include?('menu'), 'menu is missing'
  end

  def test_platform_site_names
    sites = @platform.site_names
    assert_equal 3, sites.size, "Got #{sites.to_s}"
    assert sites.include?('default')
    assert sites.include?('www.foo.org')
    assert sites.include?('www.bar.org')
  end

end # TestDrupidPlatform
