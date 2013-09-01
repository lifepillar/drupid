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

class TestDrupidDownloadStrategyCurl < MiniTest::Unit::TestCase

  def setup
    @temp_dir = FIXTURES + 'templib'
    @temp_dir.mkpath
  end

  def teardown
    @temp_dir.rmtree
  end

  def test_fetch_using_local_url
    url = "file://#{FIXTURES + 'fake_library.tar.gz'}"
    downloader = Drupid::DownloadStrategy::Curl.new url, @temp_dir
    downloader.fetch
    assert((@temp_dir+'fake_library.tar.gz').exist?, 'Archive not fetched')
  end

  def test_fetch_using_local_url_and_name
    url = "file://#{FIXTURES + 'fake_library.tar.gz'}"
    downloader = Drupid::DownloadStrategy::Curl.new url, @temp_dir, 'foobar'
    downloader.fetch
    assert((@temp_dir+'foobar.tar.gz').exist?, 'Archive not fetched or name not correct')
  end

  def test_fetch_cannot_be_used_with_local_path
    url = FIXTURES+'fake_library.tar.gz'
    downloader = Drupid::DownloadStrategy::Curl.new url, @temp_dir
    assert_raises Drupid::DownloadStrategy::CurlError do
      downloader.fetch
    end
  end

  def test_stage
    url = "file://#{FIXTURES + 'fake_library.tar.gz'}"
    downloader = Drupid::DownloadStrategy::Curl.new url, @temp_dir
    assert_equal url, downloader.url, 'URL incorrect'
    assert_equal @temp_dir, downloader.dest, 'dest incorrect'
    assert_equal nil, downloader.name, 'name incorrect'
    downloader.fetch
    downloader.stage
    assert_equal @temp_dir+'fake_library', downloader.staged_path, 'Incorrect staged_path'
    assert((@temp_dir+'fake_library.tar.gz').exist?, 'Archive not fetched')
    assert((@temp_dir+'fake_library').exist?, 'Archive not staged')
    assert((@temp_dir+'fake_library').directory?, 'Staged archive is not a directory')
  end

  def test_stage_with_custom_name
    url = "file://#{FIXTURES+ 'fake_library.tar.gz'}"
    downloader = Drupid::DownloadStrategy::Curl.new url, @temp_dir, 'custom-name'
    assert_equal url, downloader.url, 'URL incorrect'
    assert_equal @temp_dir, downloader.dest, 'dest incorrect'
    assert_equal 'custom-name', downloader.name, 'name incorrect'
    downloader.fetch
    downloader.stage
    assert_equal @temp_dir+'custom-name', downloader.staged_path, 'Incorrect staged_path'
    assert((@temp_dir+'custom-name.tar.gz').exist?, 'Archive not fetched')
    assert((@temp_dir+'custom-name').exist?, 'Archive not staged')
    assert((@temp_dir+'custom-name').directory?, 'Staged archive is not a directory')
  end

  def test_fetch_and_stage_text_file
    url = "file://#{FIXTURES + 'drupal-example.make'}"
    downloader = Drupid::DownloadStrategy::Curl.new url, @temp_dir
    downloader.fetch
    assert((@temp_dir+'drupal-example.make').exist?, 'Text file not fetched')
    downloader.stage
    assert_equal @temp_dir+'drupal-example.make', downloader.staged_path, 'Incorrect staged_path'
    assert((@temp_dir+'drupal-example.make').exist?, 'Text file not staged correctly')
    assert_equal 1, @temp_dir.children.size, 'The working dir should not contain other files'
  end

  def test_fetch_and_stage_text_file_with_custom_name
    url = "file://#{FIXTURES + 'drupal-example.make'}"
    downloader = Drupid::DownloadStrategy::Curl.new url, @temp_dir, 'foo.make'
    assert_equal url, downloader.url, 'URL incorrect'
    assert_equal @temp_dir, downloader.dest, 'dest incorrect'
    assert_equal 'foo.make', downloader.name, 'name incorrect'
    downloader.fetch
    assert((@temp_dir+'foo.make').exist?, 'Text file not fetched')
    refute((@temp_dir+'drupal-example.make').exist?, 'Spurious file')
    downloader.stage
    assert_equal @temp_dir+'foo.make', downloader.staged_path, 'Incorrect staged_path'
    assert((@temp_dir+'foo.make').exist?, 'Text file not staged correctly')
    assert_equal 1, @temp_dir.children.size, 'The working dir should not contain other files'
  end

end # TestDrupidDownloadStrategyCurl
