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

  if RUBY_PLATFORM =~ /darwin/
    @@cache_path = Pathname.new(ENV['HOME']) + 'Library/Caches/Drupid'
  else
    @@cache_path = Pathname.new(ENV['HOME']) + '.drupid_cache'
  end

  def Drupid.cache_path
    @@cache_path
  end

  def Drupid.cache_path=(new_path)
    raise "Invalid cache path" unless new_path.to_s =~ /cache/i
    @@cache_path = Pathname.new(new_path).realpath # must exist
  end

  class Component
    include Drupid::Utils

    attr          :name
    attr_accessor :download_url
    attr_accessor :download_type
    attr_accessor :download_specs
    attr_accessor :overwrite
    attr_accessor :local_path
    attr          :ignore_paths

    def initialize name
      @name           = name
      @download_url   = nil
      @download_type  = nil
      @download_specs = Hash.new
      @overwrite      = false
      @subdir         = nil
      @directory_name = nil
      @local_path     = nil
      @ignore_paths   = Array.new
      @patches        = Array.new
    end

    # Performs a deep copy of this object.
    def clone
      Marshal.load(Marshal.dump(self))
    end

    def extended_name
      @name
    end

    # A synonym for #extended_name.
    def to_s
      extended_name
    end

    # Returns a path to a subdirectory where this component
    # should be installed. The path is meant to be relative
    # to the 'default' installation path (e.g., 'sites/all/modules' for modules,
    # 'sites/all/themes' for themes, 'profiles' for profiles, etc...).
    # For example, if a module 'foobar' must be installed under 'sites/all/modules'
    # and this property is set, say, to 'contrib', then the module will be installed
    # at 'sites/all/modules/contrib/foobar'.
    def subdir
      (@subdir) ? Pathname.new(@subdir) : Pathname.new('.')
    end

    # Sets the path to a subdirectory where this component should be installed,
    # relative to the default installation path.
    def subdir=(d)
      @subdir = d
    end

    # Returns the directory name for this component.
    def directory_name
      return @directory_name.to_s if @directory_name
      return local_path.basename.to_s if exist?
      return name
    end

    # Sets the directory name for this component.
    def directory_name=(d)
      @directory_name = d
    end

    # Returns true if this project is associated to a local copy on disk;
    # returns false otherwise.
    def exist?
      @local_path and @local_path.exist?
    end

    def add_download_spec(spec, ref)
      @download_specs.merge!({spec => ref})
    end

    # Downloads to local cache.
    def fetch
      if cached_location.exist?
        @local_path = cached_location
        debug "#{extended_name} is cached"
      else
        raise "No download URL specified for #{extended_name}" if download_url.nil?
        blah "Fetching #{extended_name}"
        downloader = Drupid.makeDownloader self.download_url.to_s,
                                           self.cached_location.dirname.to_s,
                                           self.cached_location.basename.to_s,
                                           self.download_specs
        downloader.fetch
        downloader.stage
        @local_path = downloader.staged_path
      end
    end

    # Applies the patches associated to this component.
    # Raises an exception if a patch cannot be applied.
    def patch
      fetch unless exist?
      return unless has_patches?
      dont_debug { patched_location.rmtree if patched_location.exist? } # Make sure that no previous patched copy exists
      dont_debug { @local_path.ditto patched_location }
      @local_path = patched_location
      # Download patches
      patched_location.dirname.cd do
        each_patch do |p|
          p.fetch
        end
      end
      # Apply patches
      patched_location.cd do
        each_patch do |p|
          p.apply
        end
      end
    end

    # Removes all the patches from this component.
    def clear_patches
      @patches.clear
    end

    # Returns true if this component has been patched;
    # returns false otherwise.
    def patched?
      @local_path == patched_location
    end
  
    # Iterates over each patch associated to this component,
    # yielding a Drupid::Patch object.
    def each_patch
      @patches.each do |p|
        yield p
      end
    end

    # Returns true if patches are associated to this component,
    # returns false otherwise.
    def has_patches?
      !@patches.empty?
    end

    def add_patch(url, descr, md5 = nil)
      @patches << Patch.new(url, descr, md5)
    end

    # Returns the first patch with the given description, or
    # nil if no such patch exists.
    def get_patch descr
      @patches.each do |p|
        return p if descr == p.descr
      end
    end

    # Full path to the location where a cached copy of this component is located.
    def cached_location
      dlt = (download_type) ? download_type : 'default'
      Drupid.cache_path + self.class.to_s.split(/::/).last + extended_name + dlt + name
    end

    # Full path to the directory where a patched copy of this component is located.
    def patched_location
      cached_location.dirname + '__patches' + name
    end

    # Ignores the given path relative to this component's path.
    # This is useful, for example, when an external library is installed
    # inside a module's folder (rather than in the libraries folder).
    def ignore_path(relative_path)
      @ignore_paths << Pathname.new(relative_path)
    end

    # Performs a file-by-file comparison of this component with another.
    # Returns a list of files that are different between the two copies.
    # If the directories of the two projects look the same, returns an empty array.
    # Local copies must exist for both projects, otherwise this method raises an error.
    #
    # If one of the projects has a makefile, the content of the following directories
    # is ignored: libraries, modules, themes.
    # Version control directories (.git) are always ignored.
    def file_level_compare_with tgt, additional_rsync_args = []
      raise "#{extended_name} does not exist at #{local_path}" unless exist?
      raise "#{tgt.extended_name} does not exist at #{tgt.local_path}" unless tgt.exist?
      args = Array.new
      default_exclusions = [
        '.DS_Store',
        '.git/',
        '.bzr/',
        '.hg/',
        '.svn/'
      ]
      default_exclusions.each { |e| args << "--exclude=#{e}" }
      ignore_paths.each       { |p| args << "--exclude=#{p}" }
      tgt.ignore_paths.each   { |p| args << "--exclude=#{p}" }
      args += additional_rsync_args
      compare_paths local_path, tgt.local_path, args
    end

  end # Component
end # Drupid
