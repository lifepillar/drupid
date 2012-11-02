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
  class PlatformProject < Project
    attr :platform

    def initialize proj_platform, project_or_info_path
      pi = ProjectInfo.new(project_or_info_path)
      super(pi.project_name, pi.project_core)
      @info_file = pi.info_file
      @local_path = pi.project_dir
      @version = pi.project_version if pi.project_version
      @proj_type = pi.project_type
      @core_project = pi.core_project?
      @platform = proj_platform
    end

    # Returns the path of this project relative to the path of the containing
    # platform.
    def relative_path
      @local_path.relative_path_from(@platform.local_path)
    end

    # A subdirectory where this project is installed.
    # For example, for 'sites/all/modules/specialmodules/mymodule',
    # this method returns 'specialmodules';
    # for 'profiles/custom_profiles/myprofile', this method returns 'custom_profiles';
    # for 'modules/node/tests/', returns 'node'.
    def subdir
      if core_project? or 'profile' == proj_type
        return @local_path.parent.relative_path_from(@platform.local_path + (proj_type + 's'))
      else
        return @local_path.parent.relative_path_from(@platform.local_path + @platform.contrib_path + (proj_type + 's'))
      end
    end

    # Returns true if this is an enabled theme
    # or an installed (enabled or disabled) module in the specified site,
    # or in at least one site in the platform if no site is specified;
    # returns false otherwise.
    # Note that the project's path must be defined, because this method uses
    # the path to determine whether the project is installed in a site.
    # Consider, for example, a Drupal platform that
    # contains two distinct copies of a module called Foo, one
    # in ./sites/www.mysite.org/modules/foo
    # and another in ./profiles/fooprofile/modules/foo. Suppose that the former is used by
    # the site www.mysite.org, and the latter is used by another site, say
    # www.othersite.org, installed using the fooprofile installation profile.
    # If p is a Drupid::PlatformProject object associated to ./sites/www.mysite.org/modules/foo
    # and q is another Drupid::PlatformProject object associated to
    # ./profiles/fooprofile/modules/foo and both modules are installed in their
    # respective sites,
    # then the result of invoking this method will be as follows:
    #   p.installed?('www.mysite.org')     # true
    #   p.installed?('www.othersite.org')  # false
    #   q.installed?('www.mysite.org')     # false
    #   q.installed?('www.othersite.org')  # true
    #   p.installed?                       # true
    #   q.installed?                       # true
    def installed? site = nil
      site_list = (site) ? [site] : platform.site_names
      site_list.each do |s|
        site_path = platform.sites_path + s
        next unless site_path.exist?
        return true if Drush.installed?(site_path, name, relative_path)
      end
      return false
    end

  end # Project
end # Drupid
