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

class TestDrupidMakefile < MiniTest::Unit::TestCase

  def setup
    @makefile = Drupid::Makefile.new(FIXTURES+'drupal-example.make')
  end

  def test_load_makefile
    assert_equal '7.x', @makefile.core
    assert_equal '2', @makefile.api
    assert_instance_of Drupid::Project, @makefile.get_project('wysiwyg')
    assert_instance_of Drupid::Version, @makefile.get_project('wysiwyg').version
    assert_instance_of Drupid::Project, @makefile.get_project('foobar')
    assert_instance_of Drupid::Library, @makefile.get_library('foolib')
    assert_nil @makefile.get_project('views').version
    assert_equal 'views', @makefile.get_project('views').name
    assert_equal '7.x-2.1', @makefile.get_project('wysiwyg').version.long
    assert_instance_of Drupid::Version, @makefile.get_project('ctools').version
    assert_equal '7.x-1.0-rc1', @makefile.get_project('ctools').version.long
    assert_equal 'contrib', @makefile.get_project('cck').subdir.to_s
    assert_equal 'git', @makefile.get_project('tao').download_type
    assert_equal 'git://github.com/developmentseed/tao.git', @makefile.get_project('tao').download_url
    assert_equal 'e4876228f449cb0c37ffa0f2142', @makefile.get_project('calendar').get_patch('rfc-fixes').md5
    assert_equal 'http://path/to/some-patch.diff', @makefile.get_project('jquery_ui').get_patch('some-patch.diff').url
    assert_instance_of Drupid::Project, @makefile.get_project('drupal')
    assert @makefile.get_project('drupal').drupal?
    assert_equal 'drupal', @makefile.get_project('drupal').name
    assert_equal '7.8', @makefile.get_project('drupal').version.short
    assert_equal '7.x-7.8', @makefile.get_project('drupal').version.long
  end

  # Version constraints are not supported yet, but they should not break Drupid.
  def test_version_constraints
    assert_instance_of Drupid::Project, @makefile.get_project('file_entity')
    assert_instance_of Drupid::Project, @makefile.get_project('patterns')
    assert_instance_of Drupid::Project, @makefile.get_project('imce')
    assert_instance_of Drupid::Project, @makefile.get_project('insert')
    assert_equal 'file_entity-7.x', @makefile.get_project('file_entity').extended_name
    assert_equal 'patterns-7.x', @makefile.get_project('patterns').extended_name
    assert_equal 'imce-7.x', @makefile.get_project('imce').extended_name
    assert_equal 'insert-7.x', @makefile.get_project('insert').extended_name
  end

  def test_makefile_project_types
    assert_equal 'theme', @makefile.get_project('tao').proj_type
  end

  def test_makefile_local_urls
    assert_equal "file://#{FIXTURES}/mymodules/foobar.zip", @makefile.get_project('foobar').download_url
    assert_equal "file://#{FIXTURES}/foolib.tar.gz", @makefile.get_library('foolib').download_url
  end

  def test_makefile_save
    @makefile.save(@makefile.path.sub_ext('.test'))
    assert File.exist?(@makefile.path.sub_ext('.test')), 'Makefile not saved'
    FileUtils.rm_f @makefile.path.sub_ext('.test')
  end

  def test_each_project
    l = []
    @makefile.each_project { |p| l << p.name }
    refute l.include?('drupal')
    assert l.include?('tao')
    assert l.include?('calendar')
  end

  def test_project_names
    projects = @makefile.project_names
    assert_equal 14, projects.size
    refute projects.include?('drupal')
    assert projects.include?('views')
    assert projects.include?('ctools')
    assert projects.include?('wysiwyg')
    assert projects.include?('cck')
    assert projects.include?('tao')
    assert projects.include?('respond')
    assert projects.include?('date')
    assert projects.include?('calendar')
    assert projects.include?('jquery_ui')
    assert projects.include?('foobar')
    assert projects.include?('file_entity')
    assert projects.include?('imce')
    assert projects.include?('insert')
    assert projects.include?('patterns')
  end

  def test_libraries
    assert_instance_of Drupid::Library, @makefile.get_library('profiler')
    assert_equal 'get', @makefile.get_library('profiler').download_type
    assert_equal 'http://ftp.drupal.org/files/projects/profiler-7.x-2.0-beta1.tar.gz', @makefile.get_library('profiler').download_url
    assert_instance_of Drupid::Library, @makefile.get_library('jquery_ui')
    assert_equal 'modules/contrib/jquery_ui', @makefile.get_library('jquery_ui').destination.to_s
  end

  def test_makefile_to_s
    mf = <<EOS
core = 7.x
api  = 2
projects[drupal][version] = "7.8"

projects[calendar][patch][rfc-fixes][url] = "http://drupal.org/files/issues/cal-760316-rfc-fixes-2.diff"
projects[calendar][patch][rfc-fixes][md5] = "e4876228f449cb0c37ffa0f2142"
projects[cck][subdir] = "contrib"
projects[ctools][version] = "1.0-rc1"
projects[] = "date"
projects[] = "file_entity"
projects[foobar][download][url] = "mymodules/foobar.zip"
projects[] = "imce"
projects[] = "insert"
projects[jquery_ui][patch][some-patch.diff][url] = "http://path/to/some-patch.diff"
projects[] = "patterns"
projects[] = "respond"
projects[tao][type] = "theme"
projects[tao][location] = "http://code.developmentseed.com/fserver"
projects[tao][download][type] = "git"
projects[tao][download][url] = "git://github.com/developmentseed/tao.git"
projects[] = "views"
projects[wysiwyg][version] = "2.1"

libraries[foolib][download][type] = "file"
libraries[foolib][download][url] = "foolib.tar.gz"
libraries[foolib][destination] = "libraries"
libraries[foolib][directory_name] = "foolib"
libraries[jquery_ui][download][type] = "file"
libraries[jquery_ui][download][url] = "http://jquery-ui.googlecode.com/files/jquery.ui-1.6.zip"
libraries[jquery_ui][download][md5] = "c177d38bc7af59d696b2efd7dda5c605"
libraries[jquery_ui][destination] = "modules/contrib/jquery_ui"
libraries[jquery_ui][directory_name] = "jquery_ui"
libraries[profiler][download][type] = "get"
libraries[profiler][download][url] = "http://ftp.drupal.org/files/projects/profiler-7.x-2.0-beta1.tar.gz"
libraries[profiler][destination] = "libraries"
libraries[profiler][directory_name] = "profiler"
libraries[shadowbox][download][type] = "post"
libraries[shadowbox][download][url] = "http://www.shadowbox-js.com/download"
libraries[shadowbox][download][file_type] = "tar.gz"
libraries[shadowbox][download][post_data] = "format=tar&adapter=jquery&players[]=img&players[]=iframe&players[]=html&players[]=swf&players[]=flv&players[]=qt&players[]=wmp&language=en&css_support=on"
libraries[shadowbox][destination] = "libraries"
libraries[shadowbox][directory_name] = "shadowbox"
EOS
    assert_equal mf, @makefile.to_s
  end

  def test_patches
    p = @makefile.get_project('calendar')
    assert p.has_patches?
    p.each_patch do |pa| # There only one patch
      assert_equal 'rfc-fixes', pa.descr
      assert_equal 'http://drupal.org/files/issues/cal-760316-rfc-fixes-2.diff', pa.url
      assert_equal 'e4876228f449cb0c37ffa0f2142', pa.md5
    end
  end

  def test_subdir
    p = @makefile.get_project('cck')
    assert_equal 'contrib', p.subdir.to_s
  end

end # TestDrupidMakefile
