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
