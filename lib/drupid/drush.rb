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
require 'yaml'

module Drupid

  # A wrapper around drush.
  module Drush extend Drupid::Utils

    DRUSH = `which drush`.strip

    def self.drush *args
      runBabyRun DRUSH, args
    end

    # Executes 'drush core-status --format=yaml' at the given path and
    # returns the output of the command.
    def self.status path, options = {}
      output = nil
      FileUtils.cd(path) do
        output = drush 'core-status', '--format=yaml'
      end
      YAML.load(output)
    end

    # Returns a list of all the existing versions of the specified project.
    def self.pm_releases project_name, options = {}
      output = drush 'pm-releases', '--all', '--format=list', project_name
      output.split("\n")
    end

    # Executes 'drush pm-download <project_name>' and
    # returns the output of the command.
    # If :working_dir is set to an existing directory, move into that directory before
    # executing the command.
    #
    # Options: source, destination, working_dir
    def self.pm_download project_name, options = {}
      args = ['pm-download', '-y']
      args << "--source=#{options[:source]}" if options[:source]
      args << "--destination\=#{options[:destination]}" if options[:destination]
      args << "--variant=profile-only"
      args << "--verbose" if $VERBOSE
      args << project_name
      if options[:working_dir] and File.directory?(options[:working_dir])
        wd = options[:working_dir]
      else
        wd = FileUtils.pwd
      end
      output = nil
      FileUtils.cd(wd) do
        output = runBabyRun DRUSH, args, :redirect_stderr_to_stdout => true
      end
      output
    end

    # Parses the output of 'drush pm-download' and returns
    # the path to the downloaded project, or nil
    # if the path cannot be determined.
    def self.download_path pm_download_output
      pm_download_output.match(/^\s*Project.+downloaded to *(.\[.+[\n\r])?\s*(.+)\./)
      return File.expand_path($~[2]) if $~
      return nil
    end

    # Parses the output of 'drush pm-download' and returns
    # the version of the downloaded project, or nil
    # if the version cannot be determined.
    def self.downloaded_version pm_download_output
      pm_download_output.match(/^\s*Project.+\((.+)\) +downloaded +to/)
      return $~[1] if $~
      return nil
    end

    # Returns the version of Drupal as a String object (e.g., '7.12')
    # if the specified path points to a Drupal site; returns nil otherwise.
    def self.drupal_version path, options = {}
      st = self.status(path, options)
      return st['drupal-version']
    end

    # Returns true if a Drupal's site is bootstrapped at the given path;
    # returns false otherwise.
    def self.bootstrapped?(path, options = {})
      st = self.status(path, options)
      return (st['bootstrap'] =~ 'Successful') ? true : false
    end

    # Returns true if the project at the given path is an enabled theme
    # or an installed (enabled or disabled) module in the given site;
    # returns false otherwise. The project's path must be relative
    # to the Drupal installation (e.g., 'sites/all/modules').
    # Note that the project path is necessary because, in general,
    # there may be several copies of the same modules at different locations
    # within a platform (in 'sites/all', in 'profiles/' and in site-specific locations).
    #
    # Options: verbose
    def self.installed?(site_path, project_name, project_path, options = {})
      begin
        output = drush 'pm-info', '--format=yaml', project_name
      rescue # site not fully bootstrapped
        return false
      end
      st = YAML.load(output)
      return false unless st.has_key?(project_name)
      type = st[project_name]['type']
      status = st[project_name]['status']
      ('module' == type and project_status !~ /not installed/) or
      ('theme'  == type and project_status =~ /^enabled/)
    end

  end # module Drush

end # Drupid
