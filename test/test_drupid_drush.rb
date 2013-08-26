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

class TestDrupidDrush < MiniTest::Unit::TestCase
  def test_recommended_release_views
    test_output = <<EOS
views,7.x-3.x-dev,2013-Jul-10,Development
views,7.x-3.7,2013-Apr-09,"Supported, Recommended"
views,7.x-3.6,2013-Mar-20,Security
views,7.x-3.5,2012-Aug-24,
views,7.x-3.4,2012-Aug-21,
views,7.x-3.3,2012-Feb-22,
views,7.x-3.2,2012-Feb-20,
views,7.x-3.1,2012-Jan-16,
views,7.x-3.0,2011-Dec-18,
views,7.x-3.0-rc3,2011-Nov-16,Security
views,7.x-3.0-rc1,2011-Jun-17,
views,7.x-3.0-beta3,2011-Mar-28,
views,7.x-3.0-beta2,2011-Mar-26,
views,7.x-3.0-beta1,2011-Mar-26,
views,7.x-3.0-alpha1,2011-Jan-06,
EOS
    assert_equal '7.x-3.7', Drupid::Drush.recommended_release(test_output)
  end

  def test_recommended_release_media
    test_output = <<EOS
media,7.x-2.x-dev,2013-Aug-23,Development
media,7.x-2.0-alpha2,2013-Aug-20,Supported
media,7.x-2.0-alpha1,2013-Aug-11,
media,7.x-2.0-unstable7,2012-Nov-18,
media,7.x-2.0-unstable6,2012-Jun-30,
media,7.x-2.0-unstable5,2012-May-20,
media,7.x-2.0-unstable4,2012-May-07,
media,7.x-2.0-unstable3,2012-Jan-12,Security
media,7.x-2.0-unstable2,2011-Oct-12,
media,7.x-2.0-unstable1,2011-Aug-10,
media,7.x-1.x-dev,2013-Aug-16,Development
media,7.x-1.3,2013-Mar-02,"Supported, Recommended"
media,7.x-1.2,2012-Jun-30,
media,7.x-1.1,2012-May-07,
media,7.x-1.0,2012-Mar-23,
media,7.x-1.0-rc3,2012-Jan-12,Security
media,7.x-1.0-rc2,2011-Oct-12,Security
media,7.x-1.0-rc1,2011-Sep-26,
media,7.x-1.0-beta5,2011-Jul-04,
media,7.x-1.0-beta4,2011-Apr-27,Security
media,7.x-1.0-beta3,2011-Jan-15,
media,7.x-1.0-beta2,2010-Nov-15,
media,7.x-1.0-beta1,2010-Oct-27,
EOS
  assert_equal '7.x-1.3', Drupid::Drush.recommended_release(test_output)
  end

  def test_supported_release_cck
    test_output = <<EOS
cck,7.x-2.x-dev,2012-Nov-20,"Supported, Development"
EOS
  assert_equal '7.x-2.x-dev', Drupid::Drush.supported_release(test_output)
  end

  def test_download_path
    test_output = <<EOS
Install location /Users/me/VirtualHosts/drupal/sites/all/themes/mothership already exists. Do you want to overwrite it? (y/n): y
Project mothership (7.x-2.2) downloaded to /Users/me/VirtualHosts/drupal/sites/all/themes/mothership.                                                          [success]
Project mothership contains 4 themes: tema, NEWTHEME, mothershipstark, mothership.

EOS
    assert_equal '/Users/me/VirtualHosts/drupal/sites/all/themes/mothership', Drupid::Drush.download_path(test_output)
  end

  def test_download_path_more
    test_output = <<EOS
Project views (7.x-3.1) downloaded to /Users/me/drupal-cache/views-7.x-3.1//views.                         [success]
Project views contains 2 modules: views, views_ui.  
EOS
    assert_equal '/Users/me/drupal-cache/views-7.x-3.1/views', Drupid::Drush.download_path(test_output)

    test_output = <<EOS
Project tao (7.x-3.0-beta4) downloaded to /Users/me/path/to/drupal-cache/tao-7.x-3.0-beta4/tao.                   [1;32;40m[1m[success][0m
  
EOS
    assert_equal '/Users/me/path/to/drupal-cache/tao-7.x-3.0-beta4/tao', Drupid::Drush.download_path(test_output)
  end

  def test_download_path_on_new_line
    test_output = <<EOS
Project respond (7.x-3.0-beta1) downloaded to                        [1;32;40m[1m[success][0m
/Users/me/here/goes/the/path/to/drupal-cache/respond-7.x-3.0-beta1/respond. 
EOS
    assert_equal '/Users/me/here/goes/the/path/to/drupal-cache/respond-7.x-3.0-beta1/respond', Drupid::Drush.download_path(test_output)

    test_output = <<EOS
Project fontyourface (7.x-2.0) downloaded to                         [1;32;40m[1m[success][0m
/Users/me/administrivia/tests/unit/drupal-cache/fontyourface-7.x-2.0//fontyourface.
Project fontyourface contains 10 modules: typekit_api, local_fonts, kernest, google_fonts_api, fontyourface_ui, fontsquirrel, fonts_com, fontdeck, font_reference, fontyourface.

EOS
    assert_equal '/Users/me/administrivia/tests/unit/drupal-cache/fontyourface-7.x-2.0/fontyourface', Drupid::Drush.download_path(test_output)
  end

  def test_bootstrapped
    res = Drupid::Drush.bootstrapped?(TESTSITE.to_s)
    refute res, 'Drupal should not be bootstrapped'
  end

end # TestDrupidDrush
