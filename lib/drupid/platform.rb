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
  class Platform
    include Drupid::Utils

    # The absolute path to this platform.
    attr :local_path
    # A Drupid::Platform::Project object with information about Drupal core,
    # or nil if this platform does not contain Drupal core.
    attr :drupal_project
    # The path for contrib modules and themes (e.g., 'sites/all'),
    # relative to #local_path.
    attr_accessor :contrib_path
    # The path to the sites directory (default: 'sites'), relative
    # relative to #local_path.
    attr :sites_dir

    # Creates a new platform object for the Drupal installation at the
    # specified path.
    def initialize(pathname)
      @local_path     = Pathname.new(pathname).realpath # must exist
      @sites_dir      = Pathname.new('sites')
      @contrib_path   = @sites_dir + 'all'
      @drupal_project = nil       # Project
      @projects       = Hash.new  # String -> PlatformProject
      @libraries      = Hash.new  # String -> Library
    end

    # Returns the version of Drupal core in this platform, or
    # nil if the version cannot be determined.
    def version
      if (@drupal_project and @drupal_project.has_version?) or load_drupal_version
        return @drupal_project.version
      end
      return nil
    end

    # Returns the full path to the sites directory in this platform, e.g.,
    # '/path/to/drupal/sites', as obtained by joining #local_path and #sites_dir.
    def sites_path
      @local_path + @sites_dir
    end

    # Returns the (possibly empty) list of sites in this platform.
    def site_names
      return [] unless sites_path.exist?
      Pathname.glob(sites_path.to_s + '/*/').map { |s| s.basename.to_s }.reject { |s| s =~ /^all$/ }
    end

    # Returns the full path to the libraries folder.
    def libraries_path
      @local_path + @contrib_path + 'libraries'
    end


    # Returns the relative path where the given component should be placed
    # in this platform.
    def dest_path(component)
      if component.instance_of?(String) # assume it is the name of a platform project
        c = get_project(component)
        raise "No project called #{component} exists in this platform" if c.nil?
      else
        c = component
      end
      if c.core_project? or c.profile?
        return c.target_path
      else
        return contrib_path + c.target_path
      end
    end

    # Returns a list of the names of the profiles that exist in this platform.
    # For profiles to be found, they must be located inside
    # the subdirectory of #local_path named 'profiles'.
    def profiles
      Pathname.glob(local_path.to_s + '/profiles/*/*.profile').map { |p| p.basename('.profile').to_s }
    end

    # Returns the Drupid::PlatformProject object with the specified name,
    # or nil if this platform does not contain a project with the given name.
    def get_project(project_name)
      return @drupal_project if @drupal_project and project_name == @drupal_project.name
      return @projects[project_name]
    end

    # Returns true if this platform contains a project with the specified name.
    def has_project?(project_name)
      @projects.has_key?(project_name) or (@drupal_project and project_name == @drupal_project.name)
    end

    # Returns true if the specified site in this platform is bootstrapped.
    # If no site is specified, returns true if the platform contains at least
    # one bootstrapped site. Returns false otherwise. Example:
    #   platform.bootstrapped?('default')
    def bootstrapped?(site = nil)
      sites_list = (site) ? [site] : site_names
      sites_list.each do |s|
        p = sites_path + s
        next unless p.exist?
        return true if Drupid::Drush.bootstrapped?(p)
      end
      return false
    end

    # Analyzes this platform.
    def analyze
      blah "Analyzing #{local_path}"
      analyze_drupal_core
      analyze_projects
      analyze_libraries
      return self
    end

    # Retrieves information about Drupal core in this platform.
    def analyze_drupal_core
      debug 'Analyzing Drupal Core...'
      @drupal_project = nil
      load_drupal_version
    end

    # Extracts information about the projects in this platform.
    # This method is invoked automatically by Drupid::Platform.analyze.
    # In general, it does not need to be called by the user.
    def analyze_projects
      @projects = Hash.new
      count = 0
      search_paths = Array.new
      search_paths << local_path+'modules/**/*.info'
      search_paths << local_path+'themes/**/*.info'
      search_paths << local_path+'profiles/*/*.info'
      search_paths << local_path+contrib_path+'modules/**/*.info'
      search_paths << local_path+contrib_path+'themes/**/*.info'
      search_paths.uniq! # contrib_path may be ''
      search_paths.each do |sp|
        Dir[sp.to_s].each do |p|
          pp = Drupid::PlatformProject.new(self, p)
          @projects[pp.name] = pp
          count += 1
        end
      end
      count
    end

    # TODO: implement method
    def analyze_libraries
    end

    # TODO: implement or throw away?
    def to_makefile()
    end

    # Returns a list of the names of all contrib projects in this platform.
    def project_names
      @projects.values.reject { |p| p.core_project? }.map { |p| p.name }
    end

    # Returns a list of the names of all core projects.
    def core_project_names
      @projects.values.select { |p| p.core_project? }.map { |p| p.name }
    end

    # Iterates over all contrib projects in this platform.
    def each_project
      @projects.values.reject { |p| p.core_project? }.each { |p| yield p }
    end

    # Iterates over all core projects in this platform.
    def each_core_project
      @projects.values.select { |p| p.core_project? }.each { |p| yield p }
    end

    # Creates an SVG image depicting the relationships
    # among the projects in this platform.
    #
    # *Requires*: the <tt>dot</tt> program. Without <tt>dot</tt>,
    # only a <tt>.dot</tt> file is created, but no SVG image.
    #
    # Returns the name of the created file.
    def dependency_graph
      silence_warnings do
        begin
          require 'rgl/adjacency'
          require 'rgl/dot'
        rescue LoadError
          odie "Please install the RGL gem with 'gem install rgl'"
        end
      end
      analyze
      # We use this instead of a dag, because there may be circular dependencies...
      graph = ::RGL::DirectedAdjacencyGraph.new
      each_project do |p|
        graph.add_vertex(p.name)
        p.dependencies(:subprojects => false).each do |depname|
          graph.add_vertex(depname) # does nothing if depname already exists
          graph.add_edge(p.name, depname)
        end
      end
      each_core_project do |p|
        next if p.name.match(/test/) # Skip test modules
        graph.add_vertex('node' == p.name ? '"node"' : p.name) # 'node' is a Dot keyword
        p.dependencies.each do |depname|
          graph.add_vertex(depname)
          graph.add_edge(p.name, depname)
        end
      end
      outfile = graph.write_to_graphic_file('svg')
      if which('dot').nil?
        owarn "The 'dot' program is required to get an SVG image."
        return outfile.sub('.svg','.dot')
      else
        return outfile
      end
    end

  private

  def load_drupal_version
    # Drupal 7 stores VERSION in bootstrap.inc. Drupal 8 moved that to /core/includes.
    bootstrap_files = ['core/includes/bootstrap.inc', 'includes/bootstrap.inc', 'modules/system/system.module']
    bootstrap_files.each do |bf|
      f = self.local_path+bf
      next unless f.exist?
      f.open('r').each_line do |l|
        if l =~ /define.*'VERSION'.*'(.+)'/
          v = $1
          debug "Drupal version detected: #{v}"
          core = v.match(/^(\d+)\./)[1].to_i
          @drupal_project = Drupid::Project.new('drupal', core, v)
          @drupal_project.local_path = self.local_path
          debug "Drupal platform has version: #{@drupal_project.version} (core: #{@drupal_project.version.core})"
          return true
        end
      end
    end
    debug "Unable to detect version of Drupal at #{self.local_path}"
    return false
  end

  end # Platform
end # Drupid
