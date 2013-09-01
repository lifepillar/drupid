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

module Drupid

  class ParseMakefileError < RuntimeError
  end
  
  # Representation of a Drush makefile.
  #
  # See also: http://drupal.org/node/625094
  class Makefile
    include Drupid::Utils

    # The absolute path to the makefile.
    attr :path
    # The value of the core field of the makefile (e.g, '7.x')
    attr :core
    # The value of the api field of the makefile (e.g., '2')
    attr :api
    # The path for contrib modules and themes (e.g., 'sites/all'),
    # relative to #path.
    attr_accessor :contrib_path

    # Creates a new Makefile object. The path must be the path
    # to a .make file (which does not need to exist).
    def initialize(path)
      @path      = Pathname.new(path)
      raise "Not an absolute path: #{@path}" unless @path.absolute?
      @core      = nil
      @api       = nil
      @projects  = Hash.new        # (String -> Project)
      @libraries = Hash.new        # (String -> Library)
      @contrib_path   = Pathname.new('sites/all')
      debug "Parsing #{@path}"
      self.reload if @path.exist?
    end

    # Reloads the makefile.
    # This method is invoked automatically at creation time
    # if a path to an existing makefile is provided.
    def reload
      @core     = nil
      @api      = nil
      @projects = Hash.new
      @libraries = Hash.new

      proj_patches = Hash.new
      libs_patches = Hash.new
      core_num = nil
      mf = File.open(@path.to_s, "r").read
      # Parse includes directives
      while mf.match(/^([ \t]*includes\[.*\]\s*=\s*"?([^\s"]+)"?[ \t]*)$/) do
        # TODO: add support for remote includes
        url = $2
        blah "Including makefile #{url}"
        inc = File.open(url, "r").read
        mf.sub!($1, inc)
      end
      if mf.match(/core *= *["']? *(\d+)\.?(\d+)?/) # Get the core number immediately
        @core = $~[1] + '.x'
        core_num = $~[1].to_i
        vers = $~[2] ? $~[1] + '.' + $~[2] : nil
        # Create Drupal project
        @projects['drupal'] = Project.new('drupal', core_num, vers)
      end
      raise ParseMakefileError, "The makefile does not contain the mandatory 'core' field" unless core_num
      lineno = 0
      mf.each_line do |line|
        lineno += 1
        next if line =~ /^\s*$/
        next if line =~ /^\s*;/
        next if line =~ /^\s*core/
        # match[1] : the key ('core', 'version', 'api', 'projects', 'libraries', 'includes')
        # match[2] : the (optional) key arguments (stuff between square brackets)
        # match[3] : the same as match[2], but without the leftmost [ and the rightmost ]
        # match[4] : the value
        # Examples:
        # (a) Given 'projects[ctools][version] = 1.0-rc1', we have
        # match[1] == 'projects'
        # match[2] == '[ctools][version]'
        # match[3] == 'ctools][version'
        # match[4] == '1.0-rc1'
        # (b) Given 'core = 7.x', we have:
        # match[1] == 'core'
        # match[3] == nil
        # match[4] == '7.x'
        match = line.match(/^\s*([^\s\[=]+)\s*(\[\s*(.*?)\s*\])?\s*=\s*["']?([^\s"'(]+)/)
        raise ParseMakefileError, "Could not parse line: #{line.strip} (line #{lineno})" if match.nil? or match.size != 5
        key = match[1]
        args = (match[3]) ? match[3].split(/\]\s*\[/) : []
        value = match[4].strip
        case key
        when 'api'
          @api = value
        when 'projects'
          if 0 == args.size # e.g., projects[] = views
            name = value
            @projects[name] = Project.new(name, core_num)
          else
            name = args[0]
            @projects[name] = Project.new(name, core_num) unless @projects.has_key?(name)
            case args.size
            when 1 # e.g., projects[views] = 2.8
              @projects[name].version = @core+'-'+value.sub(/^#{@core}-/,'')
            when 2 # e.g., projects[views][version] = 2.8 or projects[calendar][patch][] = 'http://...'
              case args[1]
              when 'version'
                @projects[name].version = @core+'-'+value.sub(/^#{@core}-/,'')
              when 'patch'
                patch_key = File.basename(value)
                patch_url = _normalize_path(value)
                @projects[name].add_patch(patch_url, patch_key)
              when 'subdir'
                @projects[name].subdir = value
              when 'location'
                @projects[name].location = _normalize_path(value)
              when 'directory_name'
                @projects[name].directory_name = value
              when 'type'
                if 'core' == value
                  @projects[name].core_project = true
                else
                  raise ParseMakefileError, "Illegal value: #{args[1]} (line #{lineno})" unless value =~ /^(module|profile|theme)$/
                  @projects[name].proj_type = value
                end
              when 'l10n_path'
                # TODO: add support for tokens
                @projects[name].l10n_path = _normalize_path(value)
              when 'l10n_url'
                @projects[name].l10n_url = _normalize_path(value)
              when 'overwrite'
                @projects[name].overwrite = true if value =~ /TRUE/i
              else
                raise ParseMakefileError, "Unknown key: #{args[1]} (line #{lineno})"
              end
            when 3 # e.g., projects[mytheme][download][type] = "svn"
              name = args[0]
              subkey = args[1]
              case subkey
              when 'download'
                case args[2]
                when 'type'
                  @projects[name].download_type = value
                when 'url'
                  @projects[name].download_url = _normalize_path(value)
                else
                  @projects[name].add_download_spec(args[2], value)
                end
              else
                raise ParseMakefileError, "Unknown key: #{subkey} (line #{lineno})"
              end
            when 4 # e.g., projects[calendar][patch][rfc-fixes][md5] = "..."
              name = args[0]
              subkey = args[1]
              case subkey
              when 'patch'
                patch_key = args[2]
                proj_patches[name] ||= Hash.new
                proj_patches[name][patch_key] ||= Hash.new
                case args[3]
                when 'url'
                  proj_patches[name][patch_key]['url'] = _normalize_path(value)
                when 'md5'
                  proj_patches[name][patch_key]['md5'] = value
                else
                  raise ParseMakefileError, "Unknown key: #{subkey} (line #{lineno})"
                end
              else
                raise ParseMakefileError, "Unknown key: #{subkey} (line #{lineno})"
              end
            else # > 4 arguments
              raise ParseMakefileError, "Too many arguments (line #{lineno})"
            end # case
          end # if
        when 'libraries'
          if 0 == args.size
            raise ParseMakefileError, "Too few arguments (line #{lineno})"
          else
            name = args[0]
            @libraries[name] = Library.new(name) unless @libraries.has_key?(name)
            case args.size
            when 1
              raise ParseMakefileError, "Too few arguments (line #{lineno})"
            when 2
              case args[1]
              when 'patch'
                patch_key = File.basename(value)
                patch_url = _normalize_path(value)
                @libraries[name].add_patch(patch_url, patch_key)
              when 'subdir'
                @libraries[name].subdir = value
              when 'destination'
                @libraries[name].destination = value
              when 'directory_name'
                @libraries[name].directory_name = value
              else
                raise ParseMakefileError, "Unknown key: #{args[1]} (line #{lineno})"
              end
            when 3 # e.g., libraries[jquery_ui][download][type] = "file"
              name = args[0]
              subkey = args[1]
              case subkey
              when 'download'
                case args[2]
                when 'type'
                  @libraries[name].download_type = value
                when 'url'
                  @libraries[name].download_url = _normalize_path(value)
                else
                  @libraries[name].add_download_spec(args[2], value)
                end
              else
                raise ParseMakefileError, "Unknown key: #{subkey} (line #{lineno})"
              end
            when 4
              name = args[0]
              subkey = args[1]
              case subkey
              when 'patch'
                patch_key = args[2]
                libs_patches[name] ||= Hash.new
                libs_patches[name][patch_key] ||= Hash.new
                case args[3]
                when 'url'
                  libs_patches[name][patch_key]['url'] = _normalize_path(value)
                when 'md5'
                  libs_patches[name][patch_key]['md5'] = value
                else
                  raise ParseMakefileError, "Unknown key: #{subkey} (line #{lineno})"
                end
              else
                raise ParseMakefileError, "Unknown key: #{subkey} (line #{lineno})"
              end
            else # > 4 arguments
              raise ParseMakefileError, "Too many arguments (line #{lineno})"
            end
          end
        when 'includes'
          owarn "Unexpected 'includes' directive (line #{lineno})"
        else
          owarn "Could not parse key: #{key} (line #{lineno})"
        end
      end
      # Add missing patches
      proj_patches.each do |proj_name, v|
        v.each do |desc,prop|
          @projects[proj_name].add_patch(prop['url'], desc, prop['md5'])
        end
      end
      libs_patches.each do |lib_name, v|
        v.each do |desc,prop|
          @libraries[lib_name].add_patch(prop['url'], desc, prop['md5'])
        end
      end
      return self
    end

    # Adds a project to this specification.
    def add_project(p)
      @projects[p.name] = p
    end

    # Returns the project with the specified name,
    # or nil if the project is not in this specification.
    def get_project(name)
      @projects[name]
    end

    # Returns the library with the specified name.
    # or nil if the library is not in this specification.
    def get_library(name)
      @libraries[name]
    end

    # Removes the project with the specified name from this specification.
    def delete_project(name)
      @projects.delete(name)
    end

    # Iterates over the projects in this specification (excluding drupal).
    def each_project
      # For convenience, return the projects in lexicographical order.
      names = @projects.keys.sort!
      names.each do |n|
        yield @projects[n] unless @projects[n].drupal?
      end
    end

    # Returns a Drupid::Project object for the Drupal core specified
    # in the makefile, or nil if the makefile does not specify a Drupal distribution.
    def drupal_project
      @projects['drupal']
    end

    # Iterates over the libraries in this specification.
    def each_library
      # For convenience, return the libraries in lexicographical order.
      names = @libraries.keys.sort!
      names.each do |n|
        yield @libraries[n]
      end
    end

    # Returns a list of the names of the projects mentioned
    # in this specification (excluding drupal).
    def project_names
      @projects.values.reject { |p| p.drupal? }.map { |p| p.name }
    end

    # Returns a list of the names of the libraries mentioned
    # in this specification.
    def library_names
      @libraries.keys
    end

    # Writes this makefile to disk.
    # An alternative location may be specified as an argument.
    def save(alt_path = @path)
      File.open(alt_path.to_s, "w").write(to_s)
    end

    # Returns this makefile as a string.
    def to_s
      s = String.new
      s << "core = #{@core}\n"
      s << "api  = #{@api}\n"
      s << _project_to_record(drupal_project) if drupal_project
      s << "\n" unless @projects.empty?
      self.each_project { |p| s << _project_to_record(p) }
      s << "\n" unless @libraries.empty?
      self.each_library { |l| s << _library_to_record(l) }
      s
    end

  private

    def _normalize_path(u)
      return u if u =~ /:\/\// # URL
      if u =~ /^\//            # Local absolute path
        return 'file://' + u
      else                     # Relative path
        return 'file://' + (path.parent + u).to_s
      end
    end

    def _relativize_path(u)
      return u unless u =~ /^file:\/\//
      return Pathname.new(u.sub(/file:\/\//,'')).relative_path_from(path.dirname).to_s
    end

    def _project_to_record(p)
      fields = Array.new
      fields << "[type] = \"#{p.proj_type}\"" if p.proj_type =~ /module|profile|theme/
      fields << "[version] = \"#{p.version.short}\"" if p.has_version?
      fields << "[location] = \"#{_relativize_path(p.location)}\"" if p.location
      fields << "[download][type] = \"#{p.download_type}\"" if p.download_type
      fields << "[download][url] = \"#{_relativize_path(p.download_url)}\"" if p.download_url
      temp = []
      p.download_specs.each do |spec,ref|
        temp << "[download][#{spec}] = \"#{ref}\""
      end
      fields = fields + temp.sort!
      p.each_patch do |pa|
        fields << "[patch][#{pa.descr}][url] = \"#{_relativize_path(pa.url)}\""
        fields << "[patch][#{pa.descr}][md5] = \"#{pa.md5}\"" if pa.md5
      end
      fields << "[l10n_path] = \"#{_relativize_path(p.l10n_path)}\"" if p.l10n_path
      fields << "[l10n_url] = \"#{_relativize_path(p.l10n_url)}\"" if p.l10n_url
      fields << "[subdir] = \"#{p.subdir}\"" if '.' != p.subdir.to_s
      fields << "[directory_name] = \"#{p.directory_name}\"" if p.directory_name != p.name
      return "projects[] = \"#{p.name}\"\n" if 0 == fields.size
      s = ''
      fields.each do |f|
        s << "projects[#{p.name}]" + f + "\n"
      end
      return s
    end

    def _library_to_record(l)
      fields = Array.new
      fields << "[download][type] = \"#{l.download_type}\"" if l.download_type
      fields << "[download][url] = \"#{_relativize_path(l.download_url)}\"" if l.download_url
      temp = []
      l.download_specs.each do |spec,ref|
        temp << "[download][#{spec}] = \"#{ref}\""
      end
      fields = fields + temp.sort!
      l.each_patch do |pa|
        fields << "[patch][#{pa.descr}][url] = \"#{pa.url}\""
        fields << "[patch][#{pa.descr}][md5] = \"#{pa.md5}\"" if pa.md5
      end
      fields << "[destination] = \"#{l.destination}\""
      fields << "[subdir] = \"#{l.subdir}\"" if '.' != l.subdir.to_s
      fields << "[directory_name] = \"#{l.directory_name}\""
      s = ''
      fields.each do |f|
        s << "libraries[#{l.name}]" + f + "\n"
      end
      return s
    end

  end # class Makefile
end # Drupid
