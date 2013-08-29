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

  # A convenience class that encapsulates methods for detecting
  # some project's properties from a local copy of a project.
  class ProjectInfo
    include Drupid::Utils

    # The project's name.
    attr :project_name
    # The project's core compatibility number. See Drupid::VersionCore.
    attr :project_core
    # The project's version. See Drupid::Version.
    attr :project_version
    # The project's type ('core', 'module', 'theme', 'profile').
    attr :project_type
    # The full path to the project's directory.
    attr :project_dir
    # The full path to the main .info file of this project
    attr :info_file

    # The argument must be the path to a .info file or a project directory.
    # If the path to a directory is passed, then this object will try
    # automatically detect the .info file inside the directory, which is
    # not a trivial task because, among the rest,
    #
    # - the .info file may be located in some sub-directory;
    # - there may be more than one .info file;
    # - the .info file name may be unrelated to the name of its containing
    #   directories.
    #
    # Faithful to its name, Drupid won't try to be too keen, and it will raise
    # an exception if it cannot reliably detect a .info file.
    def initialize(project_or_info_path)
      p = Pathname.new(project_or_info_path).realpath # must exist
      @project_core = nil
      @project_type = nil
      @project_version = nil
      if '.info' == p.extname
        @project_name = p.basename('.info').to_s
        @info_file = p
        grandparent = @info_file.parent.parent
        if grandparent.basename.to_s == @project_name
          @project_dir = grandparent
        else
          @project_dir = @info_file.parent
        end
      else
        @project_name = p.basename.to_s
        @project_dir = p
        @info_file = _identify_main_info_file
      end
      debug "Parsing project info from #{@info_file}"
      _parse_info_file
    end

    def core_project?
      @is_core_project
    end

  private

    # Returns the absolute path of the "main" .info file of this project.
    # The first file satisfying one of the following heuristics is returned:
    #
    # 1. './#name.info' exists.
    # 2. './#name/#name.info' exists.
    # 3. './<any name>.info' exists and no other .info file exists at the top-level.
    # 4. './#name/<any name>.info' exists and no other .info file exists inside './#name'.
    # 5. There is a unique .info file, anywhere inside the project's folder.
    #
    # If none of the above is satisfied, pick any .info file and set the
    # project's name after the .info file's 'project' field (if any). Then
    # return that .info file.
    #
    # Finally, if the .info file has no 'project' field, give up
    # hoping that one day Drupal will have better specifications and that people
    # will eventually follow the specifications—but complain fiercely
    # by raising an exception.
    def _identify_main_info_file
      attempts = [
        @project_dir + (@project_name + '.info'),
        @project_dir + @project_name + (@project_name + '.info'),
        @project_dir + '*.info',
        @project_dir + @project_name + '*.info',
        @project_dir+'**/*.info'
      ]
      attempts.each do |p|
        list = Pathname.glob(p.to_s)
        if 1 == list.size and list.first.exist?
          # Set the project's name after the .info file name
          @project_name = list.first.basename('.info').to_s
          return list.first
        end
      end
      # We get here if all the above has failed.
      Pathname.glob(@project_dir.to_s+'/**/*.info').each do |p|
        data = p.open("r").read
        match = data.match(/project\s*=\s*["']?(.+)["']?/)
        unless match.nil?
          @project_name = match[1].strip
          return p
        end
      end
      # Give up :/
      raise "The .info file for #{@project_name} cannot be reliably detected"
    end

    # Extracts the relevant information from the .info file.
    def _parse_info_file
      _read_info_file
      _check_project_name
      _set_project_version
      _set_project_type
    end

    # Reads the content of the .info file into a hash.
    # Parses only 'simple' key-value pairs (of the form X = v).
    # Then, check for some other keys useful to determine the project's type
    # (e.g, 'stylesheets')
    def _read_info_file
      @info_data = Hash.new
      data = @info_file.open("r").read
      data.each_line do |l|
        next if l =~ /^\s*$/
        next if l =~ /^\s*;/
        if l.match(/^(.+)=(.+)$/)
          key   = $~[1].strip
          value = $~[2].strip.gsub(/\A["']|["']\Z/, '')
          @info_data[key] = value
        end
      end
      @info_data['stylesheets'] = true if data.match(/^\s*stylesheets */)
      @info_data['regions'] = true if data.match(/^\s*regions */)
    end

    # If the .info file name differs from the name of the containing directory
    # and the .info file contains a 'project' field, do the following:
    #
    # - if <project name>.info does not exist and if the 'project' field is
    #   the same as the .info file name or the directory name, update the project's
    #   name accordingly.
    #
    # This check will fix, for example, the project's name for a project like
    # Google Analytics, whose project's name is 'google_analytics' but the .info
    # file is called 'googleanalytics.info'.
    # It will also fix the project's name when the directory name has been
    # changed and this object has been passed the path to the project's directory
    # rather than the path to the .info file.
    #
    # Testing that <project name>.info does not exist is necessary to avoid
    # renaming projects when more than one .info file exists in the same directory
    # (see for example the Entity module).
    def _check_project_name
      dirname = @project_dir.basename.to_s
      if @project_name != dirname and # E.g., 'featured_news' != 'featured_news_feature'
      !(@info_file.dirname+(dirname+'.info')).exist? and # E.g., '.../featured_news_feature/featured_news_feature.info' does not exist
      @info_data.has_key?('project')
        pn = @info_data['project']
        if pn == @info_file.basename('.info').to_s or pn == dirname
          @project_name = pn
        end
      end
    end

    def _set_project_core
      @info_data['core'].match(/^(\d+)\.x$/)
      raise "Missing mandatory core compatibility for #{@project_name}" unless $1
      @project_core = VersionCore.new($1)
    end

    def _set_project_version
      _set_project_core
      if @info_data.has_key?('version')
        v = @info_data['version']
        v = @project_core.to_s + '-' + v if v !~ /^#{@project_core}-/
        @project_version = Version.from_s(v)
      else
        @project_version = nil
      end   
    end

    # *Requires:* @info_data must not be nil
    def _set_project_type
      # Determine whether this is a core project
      if (@info_data.has_key?('package') and @info_data['package'] =~ /Core/i) or
      (@info_data.has_key?('project') and @info_data['project'] =~ /drupal/i)
        @is_core_project = true
      else
        @is_core_project = false
      end
      # Determine the project's type (module, profile or theme)
      if @info_file.sub_ext('.profile').exist?
        @project_type = 'profile'
      elsif @info_file.sub_ext('.module').exist?
        @project_type = 'module'
      elsif @info_data.has_key?('engine')  or
      @info_data.has_key?('Base theme') or
      @info_data.has_key?('base theme') or
      @info_data.has_key?('stylesheets') or
      @info_data.has_key?('regions')
        @project_type = 'theme'
      end
      # If the above didn't work, examine the path the project is in as a last resort.
      # This is needed, at least, to avoid "type cannot be determined" errors
      # for some test directories in Drupal Core, which contain an .info file
      # but no other file :/
      unless project_type
        @project_dir.each_filename do |p|
          case p
          when 'modules'
            @project_type = 'module'
          when 'themes'
            @project_type = 'theme'
          when 'profiles'
            @project_type = 'profile'
          end
        end
      end
      raise "The project's type for #{@project_name} cannot be determined" unless @project_type
    end

  end # ProjectInfo


  # Base class for projects.
  class Project < Component
    include Comparable

    attr          :core
    attr_accessor :location
    # The type of this project, which is one among 'drupal', 'module', 'theme'
    # and 'profile', or nil if the type has not been determined or assigned.
    # Note that this does not coincide with the 'type' field in a Drush makefile,
    # whose feasible values are 'core', 'module', 'theme', 'profile'.
    attr_accessor :proj_type
    attr_accessor :l10n_path
    attr_accessor :l10n_url

    # Creates a new project with a given name and compatibility number.
    # Optionally, specify a short version string (i.e., a version string
    # without core compatibility number).
    #
    # Examples:
    #   p = Drupid::Project.new('cck', 6)
    #   p = Drupid::Project.new('views', 7, '1.2')
    def initialize name, core_num, vers = nil
      super(name)
      @core = VersionCore.new(core_num)
      @core_project = ('drupal' == @name) ? true : nil
      @version = vers ? Version.from_s(@core.to_s + '-' + vers) : nil
      @proj_type = ('drupal' == @name) ? 'drupal' : nil
      @info_file = nil
    end

    # Returns true if a version is specified for this project, false otherwise.
    def has_version?
      nil != @version
    end

    # Returns the version of this project as a Drupid::Version object,
    # or nil if this project has not been assigned a version.
    def version
      @version
    end

    # Assigns a version to this project.
    # The argument must be a String object or a Drupid::Version object.
    # For the syntax of the String argument, see Drupid::Version.
    def version=(new_version)
      if new_version.is_a?(Version)
        temp_version = new_version
      elsif new_version.is_a?(String)
        v = new_version
        temp_version = Version.from_s(v)
      else
        raise NotDrupalVersionError
      end
      raise NotDrupalVersionError, "Incompatible version for project #{extended_name}: #{temp_version.long}" if temp_version.core != core
      @version = temp_version
    end

    # Updates the version of this project to the latest (stable) release.
    #
    # See also: Drupid::Project.best_release
    #
    # *Requires:* a network connection.
    def update_version
      self.version = self.best_release
      debug "Version updated: #{extended_name}"
    end

    # Returns true if this object corresponds to Drupal core;
    # returns false otherwise.
    def drupal?
      'drupal' == proj_type
    end

    # Returns true if this is a profile; returns false otherwise.
    def profile?
      'profile' == proj_type
    end

    # Returns true if this is a core project; returns false otherwise.
    def core_project?
      @core_project
    end

    def core_project=(c)
      @core_project = c
    end

    # See Version for the reason why we define == explicitly.
    def ==(other)
      @name == other.name and
      @core == other.core and
      @version == other.version
    end

    # Compares this project with another to determine which is newer.
    # The comparison returns nil if the two projects have different names
    # or at least one of them has no version;
    # otherwise, returns -1 if this project is older than the other,
    # 1 if this project is more recent than the other,
    # 0 if this project has the same version as the other.
    def <=>(other)
      return nil if @name != other.name
      c = core <=> other.core
      if 0 == c
        return nil unless has_version? and other.has_version?
        return version <=> other.version
      else
        return c
      end
    end

    # Returns the name and the version of this project as a string, e.g.,
    # 'media-7.x-2.0-unstable2' or 'drupal-7.14'.
    # If no version is specified for this project,
    # returns only the project's name and core compatibility number.
    def extended_name
      if has_version?
        return name + '-' + ((drupal?) ? version.short : version.long)
      else
        return name + '-' + core.to_s
      end
    end

    # Returns a list of the names of the extensions (modules and themes) upon
    # which this project and its subprojects (the projects contained within
    # this one) depend.
    # Returns an empty list if no local copy of this project exists.
    #
    # If :subprojects is set to false, subprojects' dependencies are not computed.
    #
    # Options: subprojects
    def dependencies options = {}
      return [] unless exist?
      deps = Array.new
      if options.has_key?(:subprojects) and (not options[:subprojects])
        reload_project_info unless @info_file and @info_file.exist?
        info_files = [@info_file]
      else
        info_files = Dir["#{local_path}/**/*.info"]
      end
      info_files.each do |info|
        f = File.open(info, "r").read
        f.each_line do |l|
          matchdata = l.match(/^\s*dependencies\s*\[\s*\]\s*=\s*["']?([^\s("']+)/)
          if nil != matchdata
            deps << matchdata[1].strip
          end
          matchdata = l.match(/^\s*base +theme\s*=\s*(.+)$/)
          if nil != matchdata
            d = matchdata[1].strip
            deps << d.gsub(/\A["']|["']\Z/, '') # Strip leading and trailing quotes
          end
        end
      end
      # Remove duplicates and self-dependency
      deps.uniq!
      deps.delete(name)
      return deps
    end

    # Returns a list of the names of the extensions (modules and themes)
    # contained in this project.
    # Returns a list containing only the project's name
    # if no local copy of this project exists.
    def extensions
      return [name] unless exist?
      # Note that the project's name may be different from the name of the .info file.
      ext = [name]
      Dir["#{local_path}/**/*.info"].map do |p|
        ext << File.basename(p, '.info')
      end
      ext.uniq!
      return ext
    end

    def reload_project_info
      project_info = ProjectInfo.new(@local_path)
      raise "Inconsistent naming: expected #{@name}, got #{project_info.project_name}" unless @name == project_info.project_name
      raise "Inconsistent core: expected #{@core}, got #{project_info.project_core}" unless @core == project_info.project_core
      @proj_type = project_info.project_type
      @core_project = project_info.core_project?
      @version = project_info.project_version
      @info_file = project_info.info_file
    end

    def fetch
      # Try to get the latest version if:
      # (1) the project is not local;
      # (2) it does not have a version already;
      # (3) no download type has been explicitly given.
      unless has_version? or download_url =~ /file:\/\// or download_type
        update_version
      end
      # If the project has no version we fetch it even if it is cached.
      # If the project has a download type, we fetch it even if it is cached
      # (say the download type is 'git' and the revision is changed in the
      # makefile, then the cached project must be updated accordingly).
      if has_version? and !download_type and cached_location.exist?
        @local_path = cached_location
        debug "#{extended_name} is cached"
      else
        blah "Fetching #{extended_name}"
        if download_type
          if download_url
            src = download_url
          elsif 'git' == download_type # Download from git.drupal.org
            src = "http://git.drupal.org/project/#{name}.git"
          else
            raise "No download URL specified for #{extended_name}" unless download_url
          end
        else
          src = extended_name
        end
        downloader = Drupid.makeDownloader src, cached_location.dirname.to_s, cached_location.basename.to_s, download_specs.merge({:type => download_type})
        downloader.fetch
        downloader.stage
        @local_path = downloader.staged_path
      end
      reload_project_info unless drupal?
    end

    # Returns the relative path where this project should be installed
    # within a platform.
    # For example, for a module called 'Foo', it might be something like
    # 'modules/contrib/foo'.
    def target_path
      case proj_type
      when 'drupal'
        return Pathname.new('.')
      when nil
        raise "Undefined project type for #{name}."
      else
        return Pathname.new(proj_type + 's') + subdir + directory_name
      end
    end

    # Returns the path to a makefile contained in this project, if any.
    # Returns nil if this project does not contain any makefile.
    # For an embedded makefile to be recognized, the makefile
    # itself must be named '#name.make' or 'drupal-org.make'.
    #
    # *Requires:* a local copy of this project.
    def makefile
      return nil unless self.exist?
      paths = [
        local_path + "#{name}.make",
        local_path + 'drupal-org.make' # Used in Drupal distributions
      ]
      paths.each do |p|
        return p if p.exist?
      end
      return nil
    end

    # Compares this project with another, returning an array of differences.
    # If this project contains a makefile, ignore the content of the following
    # directories inside the project: libraries, modules, profiles and themes.
    def file_level_compare_with tgt
      args = Array.new
      if makefile
        args << '-f' << '- /libraries/***' # this syntax requires rsync >=2.6.7.
        args << '-f' << '- /modules/***'
        args << '-f' << '- /profiles/***'
        args << '-f' << '- /themes/***'
      end
      if drupal?
        args << '-f' << '+ /profiles/default/***'  # D6
        args << '-f' << '+ /profiles/minimal/***'  # D7
        args << '-f' << '+ /profiles/standard/***' # D7
        args << '-f' << '+ /profiles/testing/***'  # D7
        args << '-f' << '- /profiles/***'
        args << '-f' << '+ /sites/all/README.txt'
        args << '-f' << '+ /sites/default/default.settings.php'
        args << '-f' << '- /sites/***'
      end
      super(tgt, args)
    end


    # Returns a Version object corresponding to the latest (stable) release
	  # of this project. If such release cannot be determined for whatever reason,
	  # returns the current version of the project.
    def best_release
      begin
        versions = Drush.pm_releases("#{self.name}-#{self.core}")
      rescue Drupid::ErrorDuringExecution => e
        owarn "Could not get release history for #{self.extended_name}"
        blah e
        return self.version
      end
      version_list = []
      if self.drupal?
        versions.each { |v| version_list.push(Version.new(self.core, v)) }
      else
        versions.each { |v| version_list.push(Version.new(self.core, v.sub("#{core}-"))) }
      end
      if self.has_version? # Exclude releases older than the current one
        version_list = version_list.select { |v| v >= self.version }
      end
      return self.version if version_list.empty?
      stable_releases = version_list.select { |v| v.stable? }
      if stable_releases.empty?
        version_list.max { |a,b| a.better b }
      else
        stable_releases.max { |a,b| a.better b }
      end
    end

  end # Project
end # Drupid
