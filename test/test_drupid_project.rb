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

class TestDrupidProjectInfo < MiniTest::Unit::TestCase

  def test_module_info_from_info_file
    module_path = TESTSITE+'sites/all/modules/views'
    pi = Drupid::ProjectInfo.new(module_path+'views.info')
    assert_equal 'views', pi.project_name
    assert_equal 'module', pi.project_type
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.x-3.1', pi.project_version.long
    assert_instance_of Pathname, pi.project_dir
    assert_equal module_path, pi.project_dir
  end

  def test_module_info_from_directory
    module_path = TESTSITE+'sites/all/modules/views'
    pi = Drupid::ProjectInfo.new(module_path)
    assert_equal 'views', pi.project_name
    assert_equal 'module', pi.project_type
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.x-3.1', pi.project_version.long
    assert_instance_of Pathname, pi.project_dir
    assert_equal module_path, pi.project_dir
  end

  def test_theme_info_from_info_file_in_subdirectory
    theme_path = TESTSITE+'sites/all/themes/subdir/mothership'
    pi = Drupid::ProjectInfo.new(theme_path+'mothership/mothership.info')
    assert_equal 'mothership', pi.project_name
    assert_equal 'theme', pi.project_type
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.x-2.2', pi.project_version.long
    assert_instance_of Pathname, pi.project_dir
    assert_equal theme_path, pi.project_dir
  end

  def test_theme_info_from_directory_in_subdirectory
    theme_path = TESTSITE+'sites/all/themes/subdir/mothership'
    pi = Drupid::ProjectInfo.new(theme_path)
    assert_equal 'mothership', pi.project_name
    assert_equal 'theme', pi.project_type
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.x-2.2', pi.project_version.long
    assert_instance_of Pathname, pi.project_dir
    assert_equal theme_path, pi.project_dir
  end

  def test_theme_info_from_info_file_no_version
    theme_path = TESTSITE+'sites/all/themes/tao'
    pi = Drupid::ProjectInfo.new(theme_path+'tao.info')
    assert_equal 'tao', pi.project_name
    assert_equal 'theme', pi.project_type
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '6.x', pi.project_core.to_s
    assert_nil pi.project_version
    assert_instance_of Pathname, pi.project_dir
    assert_equal theme_path, pi.project_dir
  end

  def test_theme_info_from_directory_no_version
    theme_path = TESTSITE+'sites/all/themes/tao'
    pi = Drupid::ProjectInfo.new(theme_path)
    assert_equal 'tao', pi.project_name
    assert_equal 'theme', pi.project_type
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '6.x', pi.project_core.to_s
    assert_nil pi.project_version
    assert_instance_of Pathname, pi.project_dir
    assert_equal theme_path, pi.project_dir
  end

  def test_core_module_info_from_info_file
    module_path = TESTSITE+'modules/node'
    pi = Drupid::ProjectInfo.new(module_path+'node.info')
    assert_equal 'node', pi.project_name
    assert_equal 'module', pi.project_type
    assert pi.core_project?
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.10', pi.project_version.short
    assert_instance_of Pathname, pi.project_dir
    assert_equal module_path, pi.project_dir
  end

  def test_core_module_info_from_directory
    module_path = TESTSITE+'modules/node'
    pi = Drupid::ProjectInfo.new(module_path)
    assert_equal 'node', pi.project_name
    assert_equal 'module', pi.project_type
    assert pi.core_project?
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.10', pi.project_version.short
    assert_instance_of Pathname, pi.project_dir
    assert_equal module_path, pi.project_dir
  end

  def test_core_theme_info_from_info_file
    theme_path = TESTSITE+'themes/garland'
    pi = Drupid::ProjectInfo.new(theme_path+'garland.info')
    assert_equal 'garland', pi.project_name
    assert_equal 'theme', pi.project_type
    assert pi.core_project?
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.10', pi.project_version.short
    assert_instance_of Pathname, pi.project_dir
    assert_equal theme_path, pi.project_dir
  end

  def test_core_theme_info_from_directory
    theme_path = TESTSITE+'themes/garland'
    pi = Drupid::ProjectInfo.new(theme_path)
    assert_equal 'garland', pi.project_name
    assert_equal 'theme', pi.project_type
    assert pi.core_project?
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.10', pi.project_version.short
    assert_instance_of Pathname, pi.project_dir
    assert_equal theme_path, pi.project_dir
  end

  def test_profile_info_from_info_file
    profile_path = TESTSITE+'profiles/openpublic'
    pi = Drupid::ProjectInfo.new(profile_path+'openpublic.info')
    assert_equal 'openpublic', pi.project_name
    assert_equal 'profile', pi.project_type
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.x-1.0-beta4', pi.project_version.long
    assert_instance_of Pathname, pi.project_dir
    assert_equal profile_path, pi.project_dir
  end

  def test_profile_info_from_directory
    profile_path = TESTSITE+'profiles/openpublic'
    pi = Drupid::ProjectInfo.new(profile_path)
    assert_equal 'openpublic', pi.project_name
    assert_equal 'profile', pi.project_type
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.x-1.0-beta4', pi.project_version.long
    assert_instance_of Pathname, pi.project_dir
    assert_equal profile_path, pi.project_dir
  end

  def test_info_for_google_analytics_from_info_file
    module_path = TESTSITE+'sites/all/modules/google_analytics'
    pi = Drupid::ProjectInfo.new(module_path+'googleanalytics.info')
    assert_equal 'google_analytics', pi.project_name
    assert_equal 'module', pi.project_type
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.x-1.2', pi.project_version.long
    assert_instance_of Pathname, pi.project_dir
    assert_equal module_path, pi.project_dir
    assert_equal 'google_analytics', pi.project_dir.basename.to_s
  end

  def test_info_for_google_analytics_from_directory
    module_path = TESTSITE+'sites/all/modules/google_analytics'
    pi = Drupid::ProjectInfo.new(module_path)
    assert_equal 'google_analytics', pi.project_name
    assert_equal 'module', pi.project_type
    assert_instance_of Drupid::VersionCore, pi.project_core
    assert_equal '7.x', pi.project_core.to_s
    assert_instance_of Drupid::Version, pi.project_version
    assert_equal '7.x-1.2', pi.project_version.long
    assert_instance_of Pathname, pi.project_dir
    assert_equal module_path, pi.project_dir
    assert_equal 'google_analytics', pi.project_dir.basename.to_s
  end

  # Rootcandy does not have "base theme" or "engine" keys in the .info file.
  # It can be recognized because it has "stylesheets" and "regions" keys.
  def test_type_for_rootcandy
    theme_path = FIXTURES+'rootcandy'
    pi = Drupid::ProjectInfo.new(theme_path)
    assert_equal 'rootcandy', pi.project_name
    assert_equal 'theme', pi.project_type
    refute pi.core_project?
  end

end # TestDrupidProjectInfo


class TestDrupidProject < MiniTest::Unit::TestCase

  def test_project_creation
    p = Drupid::Project.new('bar', 7)
    assert_instance_of Drupid::Project, p
    assert_equal 'bar', p.name
    assert_equal 7, p.core.to_i
    refute p.has_version?
  end

  def test_project_version
    p = Drupid::Project.new('foo', 8)
    p.version = '8.x-1.0'
    assert_instance_of Drupid::Project, p
    assert_equal 'foo', p.name
    assert_equal 8, p.core.to_i
    assert_instance_of Drupid::Version, p.version
    assert_equal '8.x-1.0', p.version.long
    assert_equal '1.0', p.version.short
    p = Drupid::Project.new('foo', 8, '1.0')
    assert_instance_of Drupid::Project, p
    assert_equal 'foo', p.name
    assert_equal 8, p.core.to_i
    assert_instance_of Drupid::Version, p.version
    assert_equal '8.x-1.0', p.version.long
    assert_equal '1.0', p.version.short
    p.version = Drupid::Version.from_s('8.x-1.1')
    assert_equal '8.x-1.1', p.version.long
    assert_equal '1.1', p.version.short
    assert_raises Drupid::NotDrupalVersionError do
      p.version = '2.0' # Missing core compatibility number
    end
    assert_raises Drupid::NotDrupalVersionError do
      p.version = '2.x' # Missing core compatibility number
    end
    assert_equal '8.x-1.1', p.version.long
    assert_raises Drupid::NotDrupalVersionError do
      p.version = '7.x-1.2' # Incompatible core compatibility number
    end
    assert_equal '8.x-1.1', p.version.long
    p.version = '8.x-2.0'
    assert_equal '8.x-2.0', p.version.long
  end

  def test_set_project_version_to_nil
    p = Drupid::Project.new('foo', 8)
    p.version = nil
    assert_nil p.version
  end

  def test_project_type_features_news
    p = Drupid::Project.new('featured_news_feature', 7)
    p.local_path = TESTSITE+'sites/all/modules/featured_news_feature'
    p.reload_project_info
    assert p.exist?, 'featured_news_feature not found'
    assert_equal 'featured_news_feature', p.name
    assert_equal false, p.core_project?, 'this is not a core project'
    assert_equal '7.x-1.0', p.version.long
    assert_equal '1.0', p.version.short
    assert_equal 'module', p.proj_type
  end

  def test_project_equality
    p1 = Drupid::Project.new('foo', 7, '1.0')
    p2 = Drupid::Project.new('foo', 7, '1.0')
    p3 = Drupid::Project.new('foo', 7, '1.0-rc1')
    p4 = Drupid::Project.new('bar', 7, '1.0')
    assert_equal p1, p2
    refute_equal p1, p3
    refute_equal p1, p4
    refute_equal p3, p4
  end

  def test_project_multiway_comparison
    p1 = Drupid::Project.new('bar', 7, '1.0')
    p2 = Drupid::Project.new('foo', 7, '1.0-rc2')
    p3 = Drupid::Project.new('foo', 7, '1.0-rc2')
    p4 = Drupid::Project.new('foo', 7, '1.0')
    p5 = Drupid::Project.new('foo', 7, '1.x-dev')
    p6 = Drupid::Project.new('foo', 7)
    assert_nil        p1 <=> p2, 'p1 <=> p2'
    assert_nil        p2 <=> p1, 'p2 <=> p1'
    assert_nil        p1 <=> p6, 'p1 <=> p6'
    assert_nil        p2 <=> p6, 'p2 <=> p6'
    assert_nil        p6 <=> p2, 'p6 <=> p2'
    assert_equal 0,   p2 <=> p3, 'p2 <=> p3'
    assert_equal 0,   p3 <=> p2, 'p3 <=> p2'
    assert_equal(-1,  p3 <=> p4, 'p3 <=> p4')
    assert_equal 1,   p4 <=> p3, 'p4 <=> p3'
    assert_equal(1,   p4 <=> p5, 'p4 <=> p5')
    assert_equal(-1,  p5 <=> p4, 'p5 <=> p4')
    assert_equal 1,   p3 <=> p5, 'p3 <=> p5'
    assert_equal(-1,  p5 <=> p3, 'p5 <=> p3')
    assert_equal p2, p3, 'p2 == p3'
    assert_equal p3, p2, 'p3 == p2'
    assert p3 < p4, 'p3 < p4'
    assert p4 > p3, 'p4 > p3'
    assert p4 > p5, 'p4 > p5'
    assert p5 < p4, 'p5 < p4'
    assert p3 > p5, 'p3 > p5'
    assert p5 < p3, 'p5 < p3'
  end

  def test_project_compare_underspecified_versions
    p = Drupid::Project.new('foo', 6)
    q = Drupid::Project.new('foo', 7, '1.0')
    assert_equal(-1, p <=> q, 'p <=> q')
    assert p < q, 'p should be older than q'
  end

  def test_cloning
    p = Drupid::Project.new('foo', 7)
    p.version = '7.x-1.0'
    p.local_path = '/dummy'
    p.download_specs = {:bar => 'abc'}
    q = p.clone
    assert_equal p, q
    assert_equal p.version, q.version
    assert_equal p.local_path, q.local_path
    p.local_path = '/tummy'
    refute_equal p.local_path, q.local_path
    assert_equal 'abc', p.download_specs[:bar]
    assert_equal p.download_specs, q.download_specs
    q.download_specs[:bar] = 'defg'
    assert_equal 'abc', p.download_specs[:bar]
    p.version = '7.x-2.0'
    refute_equal p.version, q.version
  end

  def test_extended_name
    p = Drupid::Project.new('views', 7, '3.1')
    assert_equal 'views-7.x-3.1', p.extended_name
    p = Drupid::Project.new('views', 8)
    assert_equal 'views-8.x', p.extended_name
  end

  def test_drupal
    p = Drupid::Project.new('drupal', 7, '7.14')
    assert_equal 'drupal', p.name
    assert_equal 'drupal-7.14', p.extended_name
    assert_equal 'drupal', p.proj_type
    assert p.core_project?, 'drupal should be a core project'
    assert_equal '.', p.target_path.to_s
  end

  def test_dependencies
    p = Drupid::Project.new('views', 7)
    p.local_path = TESTSITE+'sites/all/modules/views'
    deps = p.dependencies
    assert_equal 1, deps.size, 'views should have one dependency'
    assert deps.include?('ctools'), 'views should depend on ctools'
    p = Drupid::Project.new('wysiwyg', 7)
    p.local_path = TESTSITE+'sites/all/modules/wysiwyg'
    deps = p.dependencies
    assert deps.empty?, 'wysiwyg should not have any dependencies'
    p = Drupid::Project.new('mothershipstark', 7)
    p.local_path = TESTSITE+'sites/all/themes/subdir/mothership/mothershipstark'
    deps = p.dependencies
    assert_equal 1, deps.size, 'mothershipstark should have one dependency'
    assert deps.include?('mothership'), 'mothershipstark should depend on mothership'
    p = Drupid::Project.new('migrate', 7)
    p.local_path = TESTSITE+'sites/all/modules/migrate'
    deps = p.dependencies
    assert_equal 6, deps.size, 'migrate should have 6 dependencies'
    assert deps.include?('taxonomy'), 'taxonomy should be included'
    assert deps.include?('image'), 'image should be included'
    assert deps.include?('comment'), 'comment should be included'
    assert deps.include?('list'), 'list should be included'
    assert deps.include?('number'), 'number should be included'
    assert deps.include?('features'), 'features should be included'
  end

  # Currently, conditional dependencies (e.g., 'file_entity (>1.99)')
  # are not supported by Drupid. Nonetheless, they should not break Drupid.
  def test_conditional_dependencies
    p = Drupid::Project.new('media', 7)
    p.local_path = TESTSITE+'sites/all/modules/media'
    deps = p.dependencies
    assert_equal 3, deps.size, 'media should have three dependencies'
    assert deps.include?('file_entity'), 'media should depend on file_entity'
    assert deps.include?('image'), 'media should depend on image'
    assert deps.include?('views'), 'media should depend on views'
  end

  def test_extensions
    p = Drupid::Project.new('ctools', 7)
    p.local_path = TESTSITE+'sites/all/modules/subdir/ctools'
    extensions = p.extensions
    refute_nil extensions, 'p.extensions should return something'
    assert_equal 10, extensions.size, "Wrong number of extensions for ctools"
    assert extensions.include?('ctools'), 'The extensions should include the module itself'
    assert extensions.include?('bulk_export')
    assert extensions.include?('views_content')
    assert extensions.include?('stylizer')
    assert extensions.include?('page_manager')
    assert extensions.include?('ctools_plugin_example')
    assert extensions.include?('ctools_custom_content')
    assert extensions.include?('ctools_ajax_sample')
    assert extensions.include?('ctools_access_ruleset')
    assert extensions.include?('bulk_export')
    p = Drupid::Project.new('tao', 7)
    p.local_path = TESTSITE+'sites/all/themes/tao'
    extensions = p.extensions
    assert_equal 1, extensions.size, 'Wrong number of extensions for tao'
    assert extensions.include?('tao'), "The extensions should include tao"
    p = Drupid::Project.new('mothership', 7)
    p.local_path = TESTSITE+'sites/all/themes/subdir/mothership'
    extensions = p.extensions
    assert_equal 4, extensions.size, 'Wrong number of extensions for mothership'
    assert extensions.include?('mothership')
    assert extensions.include?('mothershipstark')
    assert extensions.include?('NEWTHEME')
    assert extensions.include?('tema')
    p = Drupid::Project.new('foobar', 7)
    assert_equal ['foobar'], p.extensions
  end

  def test_extensions_entity
    p = Drupid::Project.new('entity', 7)
    p.local_path = TESTSITE+'sites/all/modules/entity'
    exts = p.extensions
    assert_equal 4, exts.size
    assert exts.include?('entity')
    assert exts.include?('entity_token')
    assert exts.include?('entity_feature')
    assert exts.include?('entity_test')
  end

  def test_extensions_google_analytics
    p = Drupid::Project.new('google_analytics', 7)
    p.local_path = TESTSITE+'sites/all/modules/google_analytics'
    exts = p.extensions
    assert_equal 2, exts.size
    assert exts.include?('google_analytics')
    assert exts.include?('googleanalytics')
  end

  def test_project_makefile
    p = Drupid::Project.new('openpublic', 7)
    p.local_path = TESTSITE+'profiles/openpublic'
    assert_instance_of Pathname, p.makefile
    assert_equal 'openpublic.make', p.makefile.basename.to_s
  end

  def test_project_has_makefile
    p = Drupid::Project.new('openpublic', 7)
    p.local_path = TESTSITE+'profiles/openpublic'
    assert p.makefile
    p = Drupid::Project.new('mothership', 7)
    p.local_path = TESTSITE+'sites/all/themes/subdir/mothership'
    assert p.makefile.nil?
  end

  def test_target_path
    p = Drupid::Project.new('featured_news_feature', 7)
    p.local_path = TESTSITE+'sites/all/modules/featured_news_feature'
    p.reload_project_info
    assert_equal 'modules/featured_news_feature', p.target_path.to_s
    p.subdir = 'contrib'
    assert_equal 'modules/contrib/featured_news_feature', p.target_path.to_s
    p.directory_name = 'featured_news'
    assert_equal 'modules/contrib/featured_news', p.target_path.to_s
    p = Drupid::Project.new('openpublic', 7)
    p.local_path = TESTSITE+'profiles/openpublic'
    p.reload_project_info
    assert_equal 'profiles/openpublic', p.target_path.to_s
    p.subdir = 'contrib'
    assert_equal 'profiles/contrib/openpublic', p.target_path.to_s
    p.directory_name = 'myprofile'
    assert_equal 'profiles/contrib/myprofile', p.target_path.to_s
    p = Drupid::Project.new('mothership', 7)
    p.local_path = TESTSITE+'sites/all/themes/subdir/mothership'
    p.reload_project_info
    assert_equal 'themes/mothership', p.target_path.to_s
    p.directory_name = 'maternavis'
    assert_equal 'themes/maternavis', p.target_path.to_s
    p.subdir = 'harbour'
    assert_equal 'themes/harbour/maternavis', p.target_path.to_s
  end

  # Requires an Internet connection
  def test_best_release_d6
    p = Drupid::Project.new('drupal', 6)
    p.update_version
    assert_instance_of Drupid::Version, p.version
    assert_equal '6.28', p.version.short
    assert_equal 6, p.version.core.to_i
    assert_nil p.download_url
    p.update_download_url
    assert_equal 'http://ftp.drupal.org/files/projects/drupal-6.28.tar.gz', p.download_url
  end

  # Requires an Internet connection
  def test_best_release_cck6
    p = Drupid::Project.new('cck', 6)
    p.update_version
    assert_instance_of Drupid::Version, p.version
    assert_equal '6.x-2.9', p.version.long
    assert_equal 6, p.version.core.to_i
    assert_nil p.download_url
    p.update_download_url
    assert_equal 'http://ftp.drupal.org/files/projects/cck-6.x-2.9.tar.gz', p.download_url
  end

end # TestDrupidProject

class TestDrupidProjectFetchAndPatch < MiniTest::Unit::TestCase

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

  def test_fetch_project_with_curl
    p = Drupid::Project.new('views', 7)
    p.download_url = 'file://' + (FIXTURES+'views.tar.gz').to_s
    p.download_type = 'file'
    p.fetch
    refute_nil p.local_path
    assert p.local_path.exist?
    # Local path and cached location will be different because the version
    # is assigned *after* the project is fetched.s
    refute_equal p.cached_location, p.local_path
    assert_equal 'module', p.proj_type
    assert_equal '7.x-3.1', p.version.long
  end

  def test_fetch_project_with_curl_specifying_version
    p = Drupid::Project.new('views', 7, '3.1')
    p.download_url = 'file://' + (FIXTURES+'views.tar.gz').to_s
    p.download_type = 'file'
    p.fetch
    refute_nil p.local_path
    assert p.local_path.exist?
    assert_equal p.cached_location, p.local_path
    assert_equal 'module', p.proj_type
    assert_equal '7.x-3.1', p.version.long
  end

  def test_apply_patch
    p = Drupid::Project.new('views', 7, '3.1')
    p.download_url = 'file://' + (FIXTURES+'views.tar.gz').to_s
    p.download_type = 'file'
    assert_nil p.local_path
    p.fetch
    refute_nil p.local_path
    patch_path = 'file://' + (FIXTURES+'views-info.diff').to_s
    refute p.has_patches?
    p.add_patch(patch_path, 'test-patch')
    before_patch = (p.local_path+'views.info').open("r").read
    assert p.has_patches?
    refute p.patched?
    p.patch
    assert p.patched?
    assert p.has_patches?
    refute_nil p.local_path
    assert_equal p.patched_location, p.local_path
    assert_match(/__patches/, p.local_path.to_s)
    after_patch = (p.local_path+'views.info').open("r").read
    refute_equal before_patch, after_patch, 'Patch not applied correctly: the files still look equal'
  end

end # TestDrupidProjectFetchAndPatch

# 
# class TestDrupidProjectCopyMoveDelete < MiniTest::Unit::TestCase
# 
#   def setup
#     @temp = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures', 'temp'))
#     FileUtils.mkdir_p @temp
#     @foo_path = File.join(@temp, 'foobar')
#     FileUtils.mkdir_p @foo_path
#     FileUtils.touch File.join(@foo_path, 'foobar.info')
#     @target = File.join(@temp, 'foobar-new')
#     FileUtils.mkdir_p @target
#     @project = Drupid::Project.new('foobar', 7)
#     @project.path = @foo_path
#   end
# 
#   def teardown
#     FileUtils.rmtree @temp
#   end
# 
#   def test_copy
#     p = Drupid::Project.new('views', 7)
#     p.path = File.join(File.dirname(__FILE__), 'fixtures', 'drupal-fake-site', 'sites', 'all', 'modules', 'views')
#     module_path = p.path
#     new_project = p.copy(File.join(@temp, 'views'))
#     assert File.exist?(File.join(@temp, 'views')), 'views directory has not been copied'
#     assert File.exist?(File.join(@temp, 'views', 'views.info')), 'the content of views dir has not been copied'
#     assert_equal module_path, p.path
#     assert_instance_of Drupid::Project, new_project
#     assert_equal p.name, new_project.name
#     assert_equal p.version, new_project.version
#     assert_equal File.join(@temp, 'views'), new_project.path
#   end
# 
#   def test_move
#     assert File.exist?(@foo_path), 'source dir does not exist'
#     assert File.exist?(File.join(@foo_path, 'foobar.info')), 'source file does not exist'
#     assert File.exist?(@target), 'target dir does not exist'
#     new_project = @project.move(@target)
#     assert File.exist?(File.join(@target, 'foobar')), 'directory not copied'
#     assert File.exist?(File.join(@target, 'foobar', 'foobar.info')), 'Dir content not copied'
#     refute File.exist?(@foo_path), 'old dir still exists'
#   end
# 
#   def test_delete
#     assert File.exist?(@foo_path), 'source dir does not exist'
#     assert File.exist?(File.join(@foo_path, 'foobar.info')), 'source file does not exist'
#     assert_equal @foo_path, @project.path
#     @project.delete
#     refute File.exist?(@foo_path), 'source dir does not exist'
#     assert_nil @project.path, 'Path should be nil'
#   end
# 
# end # TestDrupidProjectCopyMoveDelete
# 
