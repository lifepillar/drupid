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

class TestDrupidUpdater < MiniTest::Unit::TestCase

  def setup
    @mf = Drupid::Makefile.new(FIXTURES+'drupal-example.make')
    @pl = Drupid::Platform.new(TESTSITE)
    @updater = Drupid::Updater.new(@mf, @pl)
  end

  def test_create_updater
    assert_instance_of Drupid::Updater, @updater
    assert_equal @mf, @updater.makefile
    assert_equal @pl, @updater.platform
    assert_instance_of Drupid::Updater::Log, @updater.log
    refute @updater.pending_actions?
  end

  def test_excluded_projects
    assert_empty @updater.excluded
    @updater.exclude ['foo','bar']
    assert_equal 2, @updater.excluded.size
    assert @updater.excluded? 'foo'
    assert @updater.excluded? 'bar'
    refute @updater.excluded? 'tom'
    assert_includes @updater.excluded, 'foo'
    assert_includes @updater.excluded, 'bar'
  end

  def test_create_update_actions
    views = Drupid::PlatformProject.new(@pl, TESTSITE+'sites/all/modules/views')
    action = Drupid::Updater::UpdateProjectAction.new(@pl, views)
    assert_instance_of Drupid::Updater::UpdateProjectAction, action
    assert action.pending?
  end
  
end # TestDrupidUpdater


class TestDrupidUpdaterLog < MiniTest::Unit::TestCase

  def test_create_updater_log
    log = Drupid::Updater::Log.new
    assert_empty log.actions
    assert_empty log.errors
    assert_empty log.warnings
    assert_empty log.notices
    assert_respond_to log, 'action'
    assert_respond_to log, 'error'
    assert_respond_to log, 'warning'
    assert_respond_to log, 'notice'   
  end

end # TestDrupidUpdaterLog
