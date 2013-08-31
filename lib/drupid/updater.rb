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
  # Helper class to build or update a Drupal installation.
  class Updater
    include Drupid::Utils

    # A Drupid::Makefile object.
    attr :makefile
    # A Drupid::Platform object.
    attr :platform
    # (For multisite platforms) the site to be synchronized.
    attr :site
    # The updater's log.
    attr :log

    # Creates a new updater for a given makefile and a given platform.
    # For multisite platforms, optionally specify a site to synchronize.
    def initialize(makefile, platform, site_name = nil)
      @makefile = makefile
      @platform = platform
      @site = site_name
      @log = Log.new
      #
      @libraries_paths = Array.new
      @core_projects = Array.new
      @derivative_builds = Array.new
      @excluded_projects = Hash.new
    end

    # Returns a list of names of projects that must be considered
    # as processed when synchronizing. This always include all
    # Drupal core projects, but other projects may be added.
    #
    # Requires: this updater's platform must have been analyzed
    # (see Drupid::Platform.analyze).
    def excluded
      @excluded_projects.keys
    end

    # Adds the given list of project names to the exclusion set of this updater.
    def exclude(project_list)
      project_list.each { |p| @excluded_projects[p] = true }
    end

    # Returns true if the given project is in the exclusion set of this updater;
    # returns false otherwise.
    def excluded?(project_name)
      @excluded_projects.has_key?(project_name)
    end

    # Returns true if there are actions that have not been
    # applied to the platform (including actions in derivative builds);
    # returns false otherwise.
    def pending_actions?
      return true if @log.pending_actions?
      @derivative_builds.each do |d|
        return true if d.pending_actions?
      end
      return false
    end

    # Enqueues a derivative build based on the specified project
    # (which is typically, but not necessarily, an installation profile).
    # Does nothing if the project does not contain any makefile whose name
    # coincides with the name of the project.
    def prepare_derivative_build(project)
      mf = project.makefile
      return false if mf.nil?
      debug "Preparing derivative build for #{mf.basename}"
      submake = Makefile.new(mf)
      subplatform = Platform.new(@platform.local_path)
      subplatform.contrib_path = @platform.dest_path(project)
      new_updater = Updater.new(submake, subplatform, site)
      new_updater.exclude(project.extensions)
      new_updater.exclude(@platform.profiles)
      @derivative_builds << new_updater
      return true
    end

    # Tries to reconcile the makefile with the platform by resolving unmet
    # dependencies and determining which projects must be installed, upgraded,
    # downgraded, moved or removed. This method does not return anything.
    # The result of the synchronization can be inspected by accessing
    # Drupid::Updater#log.
    #
    # This method does not modify the platform at all, it only preflights changes
    # and caches the needed stuff locally. For changes to be applied,
    # Drupid::Updater#apply_changes must be invoked after this method
    # has been invoked.
    #
    # If :nofollow is set to true, then this method does not try to resolve missing
    # dependencies: it only checks the projects that are explicitly mentioned
    # in the makefile. If :nocore is set to true, only contrib projects are
    # synchronized; otherwise, Drupal core is synchronized, too.
    #
    #
    # See also: Drupid::Updater#apply_changes
    #
    # Options: nofollow, nocore, nolibs
    def sync(options = {})
      @log.clear
      @platform.analyze
      # These paths are needed because Drupal allows libraries to be installed
      # inside modules. Hence, we must ignore them when synchronizing those modules.
      @makefile.each_library do |l|
        @libraries_paths << @platform.local_path + @platform.contrib_path + l.target_path
      end
      # We always need a local copy of Drupal core (either the version specified
      # in the makefile or the latest version), even if we are not going to
      # synchronize the core, in order to extract the list of core projects.
      if get_drupal
        if options[:nocore]
          blah "Skipping core"
        else
          sync_drupal_core
        end
      else
        return
      end
      sync_projects(options)
      sync_libraries unless options[:nolibs]
      # Process derivative builds
      @derivative_builds.each do |updater|
        updater.sync(options.merge(:nocore => true))
        @log.merge(updater.log)
      end
      return
    end

    def get_drupal
      drupal = @makefile.drupal_project
      unless drupal # Nothing to do
        owarn 'No Drupal project specified.'
        return false
      end
      return false unless _fetch_and_patch(drupal)
      # Extract information about core projects, which must not be synchronized
      temp_platform = Platform.new(drupal.local_path)
      temp_platform.analyze
      @core_projects = temp_platform.core_project_names
      return true
    end

    # Synchronizes Drupal core.
    # Returns true if the synchronization is successful;
    # returns false otherwise.
    def sync_drupal_core
      if @platform.drupal_project
        _compare_versions @makefile.drupal_project, @platform.drupal_project
      else
        log.action(InstallProjectAction.new(@platform, @makefile.drupal_project))
      end
      return true
    end

    # Synchronizes projects between the makefile and the platform.
    #
    # Options: nofollow
    def sync_projects(options = {})
      exclude(@core_projects) # Skip core projects
      processed = Array.new(excluded) # List of names of processed projects
      dep_queue = Array.new # Queue of Drupid::Project objects whose dependencies must be checked. This is always a subset of processed.

      @makefile.each_project do |makefile_project|
        dep_queue << makefile_project if sync_project(makefile_project)
        processed += makefile_project.extensions
      end

      unless options[:nofollow]
        # Recursively get dependent projects.
        # An invariant is that each project in the dependency queue has been processed
        # and cached locally. Hence, it has a version and its path points to the
        # cached copy.
        while not dep_queue.empty? do
          project = dep_queue.shift
          project.dependencies.each do |dependent_project_name|
            unless processed.include?(dependent_project_name)
              debug "Queue dependency: #{dependent_project_name} <- #{project.extended_name}"
              new_project = Project.new(dependent_project_name, project.core)
              dep_queue << new_project if sync_project(new_project)
              @makefile.add_project(new_project)
              processed += new_project.extensions
            end
          end
        end
      end

      # Determine projects that should be deleted
      pending_delete = @platform.project_names - processed
      pending_delete.each do |p|
        proj = platform.get_project(p)
        if proj.installed?(site)
          log.error "#{proj.extended_name} cannot be deleted because it is installed"
        end
        log.action(DeleteAction.new(platform, proj))
      end
    end

    # Performs the necessary synchronization actions for the given project.
    # Returns true if the dependencies of the given project must be synchronized, too;
    # returns false otherwise.
    def sync_project(project)
      return false unless _fetch_and_patch(project)

      # Does this project contains a makefile? If so, enqueue a derivative build.
      has_makefile = prepare_derivative_build(project)

      # Ignore libraries that may be installed inside this project
      pp = @platform.local_path + @platform.dest_path(project)
      @libraries_paths.each do |lp|
        if lp.fnmatch?(pp.to_s + '/*')
          project.ignore_path(lp.relative_path_from(pp))
          @log.notice("Ignoring #{project.ignore_paths.last} inside #{project.extended_name}")
        end
      end

      # Does the project exist in the platform? If so, compare the two.
      if @platform.has_project?(project.name)
        platform_project = @platform.get_project(project.name)
        # Fix project location
        new_path = @platform.dest_path(project)
        if @platform.local_path + new_path != platform_project.local_path
          log.action(MoveAction.new(@platform, platform_project, new_path))
          if (@platform.local_path + new_path).exist?
            log.error("#{new_path} already exists. Use --force to overwrite.")
          end
        end
        # Compare versions and log suitable actions
        _compare_versions project, platform_project

      # If analyzing the platform does not detect the project (e.g., Fusion),
      # we try to see if the directory exists where it is supposed to be.
      elsif (@platform.local_path + @platform.dest_path(project)).exist?
        begin
          platform_project = PlatformProject.new(@platform, @platform.local_path + @platform.dest_path(project))
        rescue => ex
          log.error("#{platform_project.relative_path} exists, but cannot be analyzed: #{ex}")
          log.action(UpdateProjectAction.new(@platform, project))
        end
        _compare_versions project, platform_project
      else # new project
        log.action(InstallProjectAction.new(@platform, project))
      end

      return (not has_makefile)
    end

    # Synchronizes libraries between the makefile and the platform.
    def sync_libraries
      debug 'Syncing libraries'
      processed_paths = []
      @makefile.each_library do |lib|
        sync_library(lib)
        processed_paths << lib.target_path
      end
      # Determine libraries that should be deleted from the 'libraries' folder.
      # The above is a bit of an overstatement, as it is basically impossible
      # to detect a "library" in a reliable way. What we actually do is just
      # deleting "spurious" paths inside the 'libraries' folder.
      # Note also that Drupid is not smart enough to find libraries installed
      # inside modules or themes.
      Pathname.glob(@platform.libraries_path.to_s + '/**/*').each do |p|
        next unless p.directory?
        q = p.relative_path_from(@platform.local_path + @platform.contrib_path)
        # If q is not a prefix of any processed path, or viceversa, delete it
        if processed_paths.find_all { |pp| pp.fnmatch(q.to_s + '*') or q.fnmatch(pp.to_s + '*') }.empty?
          l = Library.new(p.basename)
          l.local_path = p
          log.action(DeleteAction.new(@platform, l))
          # Do not need to delete subdirectories
          processed_paths << q
        end
      end
    end
    
    def sync_library(lib)
      return false unless _fetch_and_patch(lib)

      platform_lib = Library.new(lib.name)
      relpath = @platform.contrib_path + lib.target_path
      libpath = @platform.local_path + relpath
      platform_lib.local_path = libpath
      if platform_lib.exist?
        begin
          diff = lib.file_level_compare_with platform_lib
        rescue => ex
          odie "Failed to verify the integrity of library #{lib.extended_name}: #{ex}"
        end
        if diff.empty?
          log.notice("#{Tty.white}[OK]#{Tty.reset}  #{lib.extended_name} (#{relpath})")
        else
          log.action(UpdateLibraryAction.new(platform, lib))
          log.notice(diff.join("\n"))
        end
      else
        log.action(InstallLibraryAction.new(platform, lib))
      end
      return true
    end

    # Applies any pending changes. This is the method that actually
    # modifies the platform. Note that applying changes may be
    # destructive (projects may be upgraded, downgraded, deleted from
    # the platform, moved and/or patched).
    # *Always* *backup* your site before calling this method!
    # If :force is set to true, changes are applied even if there are errors.
    #
    # See also: Drupid::Updater.sync
    #
    # Options: force, no_lockfile
    def apply_changes(options = {})
      raise "No changes can be applied because there are errors." if log.errors? and not options[:force]
      log.apply_pending_actions
      @derivative_builds.each { |updater| updater.apply_changes(options.merge(:no_lockfile => true)) }
      @log.clear
      @derivative_builds.clear
    end

  private

    # Returns true if the given component is successfully cached and patched;
    # return false otherwise.
    def _fetch_and_patch component
      begin
        component.fetch
      rescue => ex
        @log.error("#{component.extended_name} could not be fetched: #{ex.message}")
        return false
      end
      if component.has_patches?
        begin
          component.patch
        rescue => ex
          @log.error("#{component.extended_name}: #{ex.message}")
          return false
        end
      end
      return true   
    end

    # Compare project versions and log suitable actions.
    def _compare_versions(makefile_project, platform_project)
      update_action = UpdateProjectAction.new(platform, makefile_project)
      case makefile_project <=> platform_project
      when 0 # up to date
        # Check whether the content of the projects is consistent
        begin
          diff = makefile_project.file_level_compare_with platform_project
        rescue => ex
          odie "Failed to verify the integrity of #{makefile_project.extended_name}: #{ex}"
        end
        p = (makefile_project.drupal?) ? '' : ' (' + (platform.contrib_path + makefile_project.target_path).to_s + ')'
        if diff.empty?
          @log.notice("#{Tty.white}[OK]#{Tty.reset}  #{platform_project.extended_name}#{p}")
        elsif makefile_project.has_patches?
          log.action(update_action)
          log.notice "#{makefile_project.extended_name}#{p} will be patched"
          log.notice(diff.join("\n"))
        else
          log.error("#{platform_project.extended_name}#{p}: mismatch with cached copy:\n" + diff.join("\n"))
          log.action(update_action)
        end
      when 1 # upgrade
        log.action(update_action)
      when -1 # downgrade
        log.action(UpdateProjectAction.new(platform, makefile_project, :downgrade => true))
        if platform_project.drupal?
          if @platform.bootstrapped?
            log.error("#{platform_project.extended_name} cannot be downgraded because it is bootstrapped (use --force to override)")
          end
        elsif platform_project.installed?(site)
          log.error("#{platform_project.extended_name}#{p} must be uninstalled before downgrading (use --force to override)")
        end
      when nil # One or both projects have no version
        # Check whether the content of the projects is consistent
        begin
          diff = makefile_project.file_level_compare_with platform_project
        rescue => ex
          odie "Failed to verify the integrity of #{component.extended_name}: #{ex}"
        end
        if diff.empty?
          log.notice("#{Tty.white}[OK]#{Tty.reset}  #{platform_project.extended_name}#{p}")
        else
          log.action(update_action)
          log.notice(diff.join("\n"))
          if platform_project.has_version? and (not makefile_project.has_version?)
            log.error("Cannot upgrade #{makefile_project.name} from known version to unknown version")
          end
        end
      end
    end

  public

    class Log
      include Drupid::Utils

      attr :actions
      attr :errors
      attr :warnings
      attr :notices

      # Creates a new log object.
      def initialize
        @actions = Array.new
        @errors = Array.new
        @warnings = Array.new
        @notices = Array.new
      end

      # Adds an action to the log.
      def action(a)
        @actions << a
        puts a.msg
      end

      def actions?
        @actions.size > 0
      end

      def pending_actions?
        @actions.find_all { |a| a.pending? }.size > 0
      end

      def apply_pending_actions
        @actions.find_all { |a| a.pending? }.each do |pa|
          pa.fire!
          puts pa.msg
        end
      end

      # Adds an error message to the log.
      def error(msg)
        @errors << msg
        ofail @errors.last
      end

      # Returns true if this log contains error messages;
      # returns false otherwise.
      def errors?
        @errors.size > 0
      end

      # Adds a warning to the log.
      def warning(msg)
        @warnings << msg
        owarn @warnings.last
      end

      def warnings?
        @warnings.size > 0
      end

      # Adds a notice to the log.
      def notice(msg)
        @notices << msg
        blah @notices.last
      end

      def notices?
        @notices.size > 0
      end

      # Clears the whole log.
      def clear
        @errors.clear
        @warnings.clear
        @notices.clear
      end

      # Appends the content of another log to this one.
      def merge(other)
        @actions += other.actions
        @errors += other.errors
        @warnings += other.warnings
        @notices += other.notices
      end

    end # class Log


    class AbstractAction
      include Drupid::Utils
      attr :platform
      attr :component

      def initialize(p, c)
        @platform = p
        @component = c
        @pending = true
      end

      def fire!
        _install # Implemented by subclasses
        @pending = false
      end

      def pending?
        @pending
      end
    end # AbstractAction


    class UpdateProjectAction < AbstractAction
      def initialize p, proj, opts = { :downgrade => false }
        raise "#{proj.extended_name} does not exist locally" unless proj.exist?
        raise "Unknown type for #{proj.extended_name}" unless proj.proj_type
        @downgrade = opts[:downgrade]
        super(p, proj)
      end

      def msg
        label = 'Update'
        if old_project = platform.get_project(component.name)
          "#{Tty.blue}[#{label}]#{Tty.white}  #{component.name}: #{old_project.version.long} => #{component.version.long}#{Tty.reset} (#{platform.dest_path(component)})"
        else
          "#{Tty.blue}[#{label}]#{Tty.white}  #{component.name}: => #{component.version.long}#{Tty.reset} (#{platform.dest_path(component)})"
        end
      end

    protected

      # Deploys a project into the specified location.
      # Note that the content of the
      # project is copied into new_path, not inside a subdirectory of new_path
      # (for example, to copy mymodule inside /some/location, new_path
      # should be set to '/some/location/mymodule').
      # Returns a new Drupid::Project object for the new location, while
      # this project remains unchanged.
      def _install
        args = Array.new
        # If the project contains a makefile, it is a candidate for a derivative build.
        # In such case, protect 'libraries', 'modules' and 'themes' subdirectories
        # from deletion.
        if component.makefile
          args << '-f' << 'P /libraries/***' # this syntax requires rsync >=2.6.7.
          args << '-f' << 'P /modules/***'
          args << '-f' << 'P /profiles/***'
          args << '-f' << 'P /themes/***'
        end
        if component.drupal?
          args = Array.new
          args << '-f' << 'R /profiles/default/***'  # D6
          args << '-f' << 'R /profiles/minimal/***'  # D7
          args << '-f' << 'R /profiles/standard/***' # D7
          args << '-f' << 'R /profiles/testing/***'  # D7
          args << '-f' << 'P /profiles/***'
          args << '-f' << 'R /sites/all/README.txt'
          args << '-f' << 'R /sites/default/default.settings.php'
          args << '-f' << 'P /sites/***'
        end
        args << '-a'
        args << '--delete'
        component.ignore_paths.each { |p| args << "--exclude=#{p}" }
        dst_path = platform.local_path + platform.dest_path(component)
        dont_debug { dst_path.mkpath }
        args << component.local_path.to_s + '/'
        args << dst_path.to_s + '/'
        begin
          runBabyRun 'rsync', args
        rescue => ex
          odie "Installing or updating #{component.name} failed: #{ex}"
        end
      end
    end # UpdateProjectAction


    class InstallProjectAction < UpdateProjectAction
      def initialize(platform, project)
        raise "#{project.name} already exists." if platform.get_project(project.name)
        super
      end

      def msg
        "#{Tty.blue}[Install]#{Tty.white} #{component.extended_name}#{Tty.reset} (#{platform.dest_path(component)})"
      end
    end # InstallProjectAction


    class UpdateLibraryAction < AbstractAction
      def initialize(platform, library)
        raise "#{library.extended_name} does not exist locally" unless library.exist?
        super
      end

      def msg
        "#{Tty.blue}[Update]#{Tty.white}  Library #{component.extended_name}#{Tty.reset} (#{platform.contrib_path + component.target_path})"
      end

    protected

      # Deploys a library into the specified location.
      def _install
        args = Array.new
        args << '-a'
        args << '--delete'
        component.ignore_paths.each { |p| args << "--exclude=#{p}" }
        dst_path = platform.local_path + platform.contrib_path + component.target_path
        dont_debug { dst_path.mkpath }
        args << component.local_path.to_s + '/'
        args << dst_path.to_s + '/'
        begin
          runBabyRun 'rsync', args
        rescue => ex
          odie "Installing or updating library #{component.name} failed: #{ex}"
        end
      end
    end # UpdateLibraryAction


    class InstallLibraryAction < UpdateLibraryAction
      def msg
        "#{Tty.blue}[Install]#{Tty.white}  Library #{component.extended_name}#{Tty.reset} (#{platform.contrib_path + component.target_path})"
      end
    end
  
    class MoveAction < AbstractAction
      # new_path must be relative to platform.local_path.
      def initialize(platform, component, new_path)
        super(platform, component)
        @destination = Pathname.new(new_path)
      end

      def fire!
        if component.local_path.exist? # may have disappeared in the meantime (e.g., because of an update)
          dst = platform.local_path + @destination
          debug "Moving #{component.local_path} to #{dst}"
          if dst.exist?
            debug "#{dst} already exists, it will be deleted"
            dont_debug { dst.rmtree }
          end
          dont_debug { dst.parent.mkpath }
          dont_debug { FileUtils.mv component.local_path.to_s, dst.to_s }
        else
          blah "Cannot move #{component.local_path.relative_path_from(platform.local_path)}\n" +
            "(It does not exist any longer)"
        end
        @pending = false
      end

      def msg
        src = component.local_path.relative_path_from(platform.local_path)
        "#{Tty.blue}[Move]#{Tty.white}    #{component.extended_name}:#{Tty.reset} #{src} => #{@destination}"
      end
    end # MoveAction


    class DeleteAction < AbstractAction
      def fire!
        debug "Deleting #{component.local_path}"
        dont_debug { component.local_path.rmtree if component.local_path.exist? }
        @pending = false
      end

      def msg
        "#{Tty.yellow}[Delete]#{Tty.white}  #{component.extended_name}#{Tty.reset} " +
          "(#{component.local_path.relative_path_from(platform.local_path)})"
      end
    end # DeleteAction

  end # Updater

end # Drupid