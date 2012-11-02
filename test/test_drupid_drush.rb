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
------- RELEASES FOR 'VIEWS' PROJECT -------
 Release         Date         Status                 
 7.x-3.x-dev     2012-Jan-30  Development            
 7.x-3.1         2012-Jan-16  Supported, Recommended 
 7.x-3.0         2011-Dec-18                         
 7.x-3.0-rc3     2011-Nov-16  Security               
 7.x-3.0-rc1     2011-Jun-17                         
 7.x-3.0-beta3   2011-Mar-28                         
 7.x-3.0-beta2   2011-Mar-26                         
 7.x-3.0-beta1   2011-Mar-26                         
 7.x-3.0-alpha1  2011-Jan-06                  
EOS
    assert_equal '7.x-3.1', Drupid::Drush.recommended_release(test_output)
  end

  def test_recommended_release_media
    test_output = <<EOS
------- RELEASES FOR 'MEDIA' PROJECT -------
 Release         Date         Status                           
 7.x-2.x-dev     2012-Jan-27  Development                      
 7.x-2.0-unstab  2012-Jan-12  Supported, Security              
 le3                                                           
 7.x-2.0-unstab  2011-Oct-12                                   
 le2                                                           
 7.x-2.0-unstab  2011-Aug-10                                   
 le1                                                           
 7.x-1.x-dev     2012-Jan-27  Development                      
 7.x-1.0-rc3     2012-Jan-12  Supported, Security, Recommended 
 7.x-1.0-rc2     2011-Oct-12  Security                         
 7.x-1.0-rc1     2011-Sep-26                                   
 7.x-1.0-beta5   2011-Jul-04                                   
 7.x-1.0-beta4   2011-Apr-27  Security                         
 7.x-1.0-beta3   2011-Jan-15                                   
 7.x-1.0-beta2   2010-Nov-15                                   
 7.x-1.0-beta1   2010-Oct-27                                   

EOS
  assert_equal '7.x-1.0-rc3', Drupid::Drush.recommended_release(test_output)
  end

  def test_supported_release_cck
    test_output = <<EOS
------- RELEASES FOR 'CCK' PROJECT -------
 Release         Date         Status                 
 7.x-2.x-dev     2011-Aug-23  Supported, Development 

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
