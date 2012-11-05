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

# Portions Copyright 2009-2011 Max Howell and other contributors.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 
#  1. Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#  2. Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
# NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

require 'pathname'
require 'uri'

module Drupid

  def self.makeDownloader uri, dest, name, download_specs = {}
    case download_specs[:type]
    when 'file'
      DownloadStrategy::Curl.new uri, dest, name, download_specs
    when 'git'
      DownloadStrategy::Git.new uri, dest, name, download_specs
    when 'svn'
      DownloadStrategy::Subversion.new uri, dest, name, download_specs
    when 'cvs'
      DownloadStrategy::CVS.new uri, dest, name, download_specs
    when 'bzr'
      DownloadStrategy::Bazaar.new uri, dest, name, download_specs
    else
      (DownloadStrategy.detect uri).new uri, dest, name, download_specs
    end
  end

  module DownloadStrategy

    def self.detect url
      case url
      when %r[^file://] then Curl
        # We use a special URL pattern for cvs
      when %r[^cvs://] then CVS
        # Standard URLs
      when %r[^bzr://] then Bazaar
      when %r[^git://] then Git
      when %r[^https?://.+\.git$] then Git
      when %r[^hg://] then Mercurial
      when %r[^svn://] then Subversion
      when %r[^svn\+http://] then Subversion
      when %r[^fossil://] then Fossil
        # Some well-known source hosts
      when %r[^https?://(.+?\.)?googlecode\.com/hg] then Mercurial
      when %r[^https?://(.+?\.)?googlecode\.com/svn] then Subversion
      when %r[^https?://(.+?\.)?sourceforge\.net/svnroot/] then Subversion
      when %r[^http://svn.apache.org/repos/] then Subversion
      when %r[^http://www.apache.org/dyn/closer.cgi] then CurlApacheMirror
        # Common URL patterns
      when %r[^https?://svn\.] then Subversion
      when %r[\.git$] then Git
      when %r[\/] then Curl
      else Drush
      end
    end

    class CurlError < RuntimeError
    end

    # [url]  The URL to download from
    # [dest] The target directory for the download
    # [name] The name (without extension) to assign to the downloaded entity
    # [download_specs] A hash of optional download parameters.
    class Base
      include Drupid::Utils
  
      attr :url
      attr :dest
      attr :name
      attr :staged_path

      def initialize url, dest, name, download_specs = {}
        @url  = url
        @dest = Pathname.new(dest).expand_path
        @name = name
        @specs = download_specs
        @staged_path = nil
        debug "#{self.class.to_s.split(/::/).last} downloader created for url=#{@url}, dest=#{@dest}, name=#{@name}"
        debug "Download specs: #{download_specs}" unless download_specs.empty?
      end
    end


    class Curl < Base
      attr :tarball_path
    
      def initialize url, dest, name = nil, download_specs = {}
        super
        if @name.to_s.empty?
          @tarball_path = @dest + File.basename(@url)
        else
          # Do not add an extension if the provided name has an extension
          n = @name.match(/\.\w+$/) ? @name : @name+ext
          @tarball_path = @dest + n
        end
        if @specs.has_key?('file_type')
          @tarball_path = @tarball_path.sub_ext('.' + @specs['file_type'])
        end
      end

    protected

      # Private method, can be overridden if needed.
      def _fetch
        if @specs.has_key?('post_data')
          curl @url, '-d', @specs['post_data'], '-o', @tarball_path
        else
          curl @url, '-o', @tarball_path
        end
      end

    public

      # Retrieves a file from this object's URL.
      def fetch
        @tarball_path.rmtree if @tarball_path.exist?
        begin
          debug "Pathname.mkpath may raise harmless exceptions"
          @dest.mkpath unless @dest.exist?
          _fetch
        rescue Exception => e
          ignore_interrupts { @tarball_path.unlink if @tarball_path.exist? }
          if e.kind_of? ErrorDuringExecution
            raise CurlError, "Download failed: #{@url}"
          else
            raise
          end
        end
        return @tarball_path
      end

      # Stages this download into the specified directory.
      # Invokes #fetch to retrieve the file if needed.
      def stage wd = @dest
        fetch unless @tarball_path.exist?
        debug "Pathname.mkpath may raise harmless exceptions"
        wd.mkpath unless wd.exist?
        target = wd + @tarball_path.basename
        type = @tarball_path.compression_type
        if type
          tempdir do # uncompress inside a temporary directory
            uncompress @tarball_path, :type => type
            # Move extracted archive into the destination
            content = Pathname.pwd.children
            if 1 == content.size and content.first.directory?
              src = content.first
              target = wd + src.basename
              FileUtils.mv src.to_s, wd.to_s, :force => true, :verbose => $DEBUG
            else # the archive did not have a root folder or it expanded to a file instead of a folder
              # We cannot move the temporary directory we are in, so we copy its content
              src = Pathname.pwd
              target = wd + src.basename
              target.rmtree if target.exist? # Overwrite
              target.mkpath
              src.ditto target
            end
            debug "Temporary staging target: #{target}"
          end
        elsif wd != @dest
          FileUtils.mv @tarball_path.to_s, wd.to_s, :force => true, :verbose => $DEBUG
        end
        if @name and @name != target.basename.to_s
          new_path = target.dirname + @name
          new_path.rmtree if new_path.exist? # Overwrite
          File.rename target.to_s, new_path.to_s
          target = target.dirname+@name
        end
        @staged_path = target
      end
  
    private

      def ext
        # GitHub uses odd URLs for zip files, so check for those
        rx=%r[https?://(www\.)?github\.com/.*/(zip|tar)ball/]
        if rx.match @url
          if $2 == 'zip'
            '.zip'
          else
            '.tgz'
          end
        else
          Pathname.new(@url).extname # uses extended extname that supports double extensions
        end
      end

    end # Curl


    class Drush < Curl
      def initialize url, dest, name, download_specs = {}
        super
        @tarball_path = @dest + @name
      end

      def _fetch
      output = Drupid::Drush.pm_download url, :destination => dest
        p = Drupid::Drush.download_path(output)
        if p
          @tarball_path = Pathname.new(p).realpath
        else
          raise "Download failed for project #{name} (using Drush):\n#{output}"
        end
      end
    end # Drush


    # Detect and download from Apache Mirror
    class CurlApacheMirror < Curl
      def _fetch
        # Fetch mirror list site
        require 'open-uri'
        mirror_list = open(@url).read()

        # Parse out suggested mirror
        #   Yep, this is ghetto, grep the first <strong></strong> element content
        mirror_url = mirror_list[/<strong>([^<]+)/, 1]

        raise "Couldn't determine mirror. Try again later." if mirror_url.nil?

        blah "Best Mirror #{mirror_url}"
        # Start download from that mirror
        curl mirror_url, '-o', @tarball_path
      end
    end # CurlApacheMirror


    class Git < Base
      def initialize url, dest, name, download_specs = {}
        super
        @clone = @dest + @name
      end

      def support_depth?
        !(@specs.has_key?('revision')) and host_supports_depth?
      end

      def host_supports_depth?
        @url =~ %r(git://) or @url =~ %r(https://github.com/)
      end

      def fetch
        raise "You must install Git." unless which "git"

        blah "Cloning #{@url}"

        if @clone.exist?
          Dir.chdir(@clone) do
            # Check for interrupted clone from a previous install
            unless system 'git', 'status', '-s'
              blah "Removing invalid .git repo from cache"
              FileUtils.rm_rf @clone
            end
          end
        end

        unless @clone.exist?
          clone_args = ['clone']
          clone_args << '--depth' << '1' if support_depth?

          if @specs.has_key?('branch')
            clone_args << '--branch' << @specs['branch']
          elsif @specs.has_key?('tag')
            clone_args << '--branch' << @specs['tag']
          end

          clone_args << @url << @clone
          git(*clone_args)
        else
          blah "Updating #{@clone}"
          Dir.chdir(@clone) do
            git 'config', 'remote.origin.url', @url

            rof =
              if @specs.has_key?('branch')
                "+refs/heads/#{@specs['branch']}:refs/remotes/origin/#{@specs['branch']}"
              elsif @specs.has_key?('tag')
                "+refs/tags/#{@specs['tag']}:refs/tags/#{@specs['tag']}"
              else
                '+refs/heads/master:refs/remotes/origin/master'
              end
            git 'config', 'remote.origin.fetch', rof

            git_args = %w[fetch origin]
            git(*git_args)
          end
        end
      end

      # Stages this download into the specified directory.
      # Invokes #fetch to retrieve the file if needed.
      def stage wd = @dest
        fetch unless @clone.exist?
        debug "Pathname.mkpath may raise harmless exceptions"
        wd.mkpath unless wd.exist?
        target = wd + @clone.basename
        Dir.chdir @clone do
          if @specs.has_key?('branch')
            git 'checkout', "origin/#{@specs['branch']}", '--'
          elsif @specs.has_key?('tag')
            git 'checkout', @specs['tag'], '--'
          elsif @specs.has_key?('revision')
            git 'checkout', @specs['revision'], '--'
          else
            # otherwise the checkout-index won't checkout HEAD
            # https://github.com/mxcl/homebrew/issues/7124
            # must specify origin/HEAD, otherwise it resets to the current local HEAD
            git 'reset', '--hard', 'origin/HEAD'
          end
          # http://stackoverflow.com/questions/160608/how-to-do-a-git-export-like-svn-export
          git 'checkout-index', '-a', '-f', "--prefix=#{target}/"
          # check for submodules
          if File.exist?('.gitmodules')
            git 'submodule', 'init'
            git 'submodule', 'update'
            sub_cmd = "git checkout-index -a -f \"--prefix=#{target}/$path/\""
            git 'submodule', '--quiet', 'foreach', '--recursive', sub_cmd
          end
        end
        @staged_path = target
      end
    end # Git


    class Subversion < Base
      def initialize  url, dest, name, download_specs = {}
        super
        @co = @dest + @name
      end

      def fetch
        @url.sub!(/^svn\+/, '') if @url =~ %r[^svn\+http://]
        blah "Checking out #{@url}"
        if @specs.has_key?('revision')
          fetch_repo @co, @url, @specs['revision']
          # elsif @specs.has_key?('revisions')
          #   # nil is OK for main_revision, as fetch_repo will then get latest
          #   main_revision = @ref.delete :trunk
          #   fetch_repo @co, @url, main_revision, true
          #
          #   get_externals do |external_name, external_url|
          #     fetch_repo @co+external_name, external_url, @ref[external_name], true
          #   end
        else
          fetch_repo @co, @url
        end
      end

      def stage wd = @dest
        fetch unless @co.exist?
        debug "Pathname.mkpath may raise harmless exceptions"
        wd.mkpath unless wd.exist?
        target = wd + @co.basename
        svn 'export', '--force', @co, target
      end

      def get_externals
        output = svn 'propget', 'svn:externals', @url
        output.chomp.each_line do |line|
          name, url = line.split(/\s+/)
          yield name, url
        end
      end

      def fetch_repo target, url, revision=nil, ignore_externals=false
        # Use "svn up" when the repository already exists locally.
        # This saves on bandwidth and will have a similar effect to verifying the
        # cache as it will make any changes to get the right revision.
        svncommand = target.exist? ? 'up' : 'checkout'
        args = [svncommand]
        args << '--non-interactive' unless @specs.has_key?('interactive') and 'true' == @specs.has_key?('interactive')
        args << '--trust-server-cert'
        # SVN shipped with XCode 3.1.4 can't force a checkout.
        #args << '--force' unless MacOS.leopard? and svn == '/usr/bin/svn'
        args << url if !target.exist?
        args << target
        args << '-r' << revision if revision
        args << '--ignore-externals' if ignore_externals
        svn(*args)
      end
    end # Subversion


    class CVS < Base
      def initialize  url, dest, name, download_specs = {}
        super
        @co = @dest + @name
      end

      def fetch
        blah "Checking out #{@url}"

        # URL of cvs cvs://:pserver:anoncvs@www.gccxml.org:/cvsroot/GCC_XML:gccxml
        # will become:
        # cvs -d :pserver:anoncvs@www.gccxml.org:/cvsroot/GCC_XML login
        # cvs -d :pserver:anoncvs@www.gccxml.org:/cvsroot/GCC_XML co gccxml
        mod, url = split_url(@url)

        unless @co.exist?
          Dir.chdir @dest do
            cvs '-d', url, 'login'
            cvs '-d', url, 'checkout', '-d', @name, mod
          end
        else
          blah "Updating #{@co}"
          Dir.chdir(@co) { cvs 'up' }
        end
      end

      def stage wd = @dest
        fetch unless @co.exist?
        debug "Pathname.mkpath may raise harmless exceptions"
        wd.mkpath unless wd.exist?
        target = wd + @co.basename
        FileUtils.cp_r Dir[(@co+"{.}").to_s], target

        require 'find'
        Find.find(Dir.pwd) do |path|
          if FileTest.directory?(path) && File.basename(path) == "CVS"
            Find.prune
            FileUtil.rm_r path, :force => true
          end
        end
      end

    private
      def split_url(in_url)
        parts=in_url.sub(%r[^cvs://], '').split(/:/)
        mod=parts.pop
        url=parts.join(':')
        [ mod, url ]
      end
    end # CVS


    class Mercurial < Base
      def initialize  url, dest, name, download_specs = {}
        super
        @clone = @dest + @name
      end

      def fetch
        blah "Cloning #{@url}"

        unless @clone.exist?
          url=@url.sub(%r[^hg://], '')
          hg 'clone', url, @clone
        else
          blah "Updating #{@clone}"
          Dir.chdir(@clone) do
            hg 'pull'
            hg 'update'
          end
        end
      end

      def stage wd = @dest
        fetch unless @co.exist?
        debug "Pathname.mkpath may raise harmless exceptions"
        wd.mkpath unless wd.exist?
        dst = wd + @co.basename
        Dir.chdir @clone do
          #if @spec and @ref
          # blah "Checking out #{@spec} #{@ref}"
          # Dir.chdir @clone do
          #   safe_system 'hg', 'archive', '-y', '-r', @ref, '-t', 'files', dst
          # end
          #else
            hg 'archive', '-y', '-t', 'files', dst
          #end
        end
      end
    end # Mercurial


    class Bazaar < Base
      def initialize  url, dest, name, download_specs = {}
        super
        @clone = @dest + @name
      end

      def fetch
        blah "Cloning #{@url}"
        unless @clone.exist?
          url=@url.sub(%r[^bzr://], '')
          # 'lightweight' means history-less
          bzr 'checkout', '--lightweight', url, @clone
        else
          blah "Updating #{@clone}"
          Dir.chdir(@clone) { bzr 'update' }
        end
      end

      def stage
        # FIXME: The export command doesn't work on checkouts
        # See https://bugs.launchpad.net/bzr/+bug/897511
        FileUtils.cp_r Dir[(@clone+"{.}").to_s], Dir.pwd
        FileUtils.rm_r Dir[Dir.pwd+"/.bzr"]
    
        #dst=Dir.getwd
        #Dir.chdir @clone do
        #  if @spec and @ref
        #    ohai "Checking out #{@spec} #{@ref}"
        #    Dir.chdir @clone do
        #      safe_system 'bzr', 'export', '-r', @ref, dst
        #    end
        #  else
        #    safe_system 'bzr', 'export', dst
        #  end
        #end
      end
    end # Bazaar


    class Fossil < Base
      def initialize  url, dest, name, download_specs = {}
        super
        @clone = @dest + @name
      end

      def fetch
        raise "You must install fossil first" unless which "fossil"

        blah "Cloning #{@url}"
        unless @clone.exist?
          url=@url.sub(%r[^fossil://], '')
          runBabyRun 'fossil', ['clone', url, @clone]
        else
          blah "Updating #{@clone}"
          runBabyRun 'fossil', ['pull', '-R', @clone]
        end
      end

      def stage
        # TODO: The 'open' and 'checkout' commands are very noisy and have no '-q' option.
        runBabyRun 'fossil', ['open', @clone]
        #if @spec and @ref
        # ohai "Checking out #{@spec} #{@ref}"
        # safe_system 'fossil', 'checkout', @ref
        #end
      end
    end # Fossil

  end # module DownloadStrategy
end # module Drupid
