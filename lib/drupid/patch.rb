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
  class Patch
    include Drupid::Utils

    attr :url
    attr :md5
    attr :descr
    attr :cached_location

    def initialize url, descr, md5 = nil
      @url = url
      @descr = descr
      @md5 = md5
      @cached_location = nil
    end

    # Downloads the patch into the current directory.
    def fetch
      dst = Pathname.pwd+File.basename(@url.to_s)
      blah "Fetching patch..."
      begin
        curl @url.to_s, '-o', dst
      rescue
        raise "Patch #{File.basename(@url.to_s)} could not be fetched."
      end
      @cached_location = dst
      debug "Patch downloaded into #{@cached_location}"
    end

    # Applies this patch in the current directory.
    # Raises an error if the patch cannot be applied.
    def apply
      debug "Applying patch at #{Dir.pwd}"
      raise "Patch not fetched." if !(@cached_location and @cached_location.exist?)
      patch_levels = ['-p1', '-p0']
      patched = false
      output = ''
      # First try with git apply
      patch_levels.each do |pl|
        begin
          runBabyRun 'git', ['apply', '--check', pl, @cached_location], :redirect_stderr_to_stdout => true
          runBabyRun 'git', ['apply', pl, @cached_location], :redirect_stderr_to_stdout => true
          patched = true
          break
        rescue => ex
          output << ex.to_s
        end
      end
      if not patched
        patch_levels.each do |pl|
          begin
            runBabyRun 'patch', ['--no-backup-if-mismatch', '-f', pl, '-d', Dir.pwd, '-i', @cached_location], :redirect_stderr_to_stdout => true
            patched = true
            break
          rescue => ex
            output << ex.to_s
          end
        end
      end
      if not patched
        if descr and descr != @cached_location.basename.to_s
          d = " (#{descr})"
        else
          d = ''
        end
        raise "Patch #{@cached_location.basename}#{d} could not be applied.\n" + output
      end
      return true
    end
  end
end
