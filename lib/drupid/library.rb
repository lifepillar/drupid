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

module Drupid
  class Library < Component

    def initialize name
      super
      self.download_type = 'file' # Default download type
      @destination = nil
    end

    def destination
      return Pathname.new('libraries') unless @destination
      return Pathname.new(@destination)
    end

    def destination=(d)
      @destination = d
    end

    # Returns the relative path where this library should be installed
    # within a platform. This is 'libraries/#name' by default.
    def target_path
      return destination + subdir + directory_name
    end

    def fetch
      debug "Cached location: #{cached_location}"
      dont_debug { cached_location.rmtree if cached_location.exist? }
      super
    end
  end # Library
end # Drupid