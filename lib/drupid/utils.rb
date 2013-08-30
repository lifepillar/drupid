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

require 'shellwords'

# Common methods, borrowed from Homebrew, which can be mixed-in by a class.
module Drupid
  module Utils

    class ErrorDuringExecution < RuntimeError
    end

    class NotAnArchiveError < RuntimeError
    end

    class Tty
      class <<self
        def blue;   bold      34; end
        def white;  bold      39; end
        def red;    underline 31; end
        def yellow; bold      33; end
        def purple; bold      35; end
        def reset;  escape     0; end
        def em;     underline 39; end
        def green;  color     92; end

      private
        def color n
          escape "0;#{n}"
        end
        def bold n
          escape "1;#{n}"
        end
        def underline n
          escape "4;#{n}"
        end
        def escape n
          "\033[#{n}m" if $stdout.tty?
        end
      end
    end

    # Prints a message.
    def ohai title, *sput
      puts "#{Tty.green}==>#{Tty.white} #{title}#{Tty.reset}"
      puts sput unless sput.empty?
    end

    # Print a warning message.
    def owarn warning
      puts "#{Tty.red}Warning#{Tty.reset}: #{warning}"
    end

    # Prints an error message.
    def ofail error, *info
      puts "#{Tty.red}Error#{Tty.reset}: #{error}"
      puts info unless info.empty?
    end

    # Prints an error message and exits.
    def odie error
      ofail error
      exit 1
    end

    # Prints debug information.
    def debug title, *info
      return unless $DEBUG
      puts "#{Tty.purple}[DEBUG]#{Tty.white} #{title}#{Tty.reset}"
      info.each do |chunk|
        chunk.each_line do |l|
          puts "#{Tty.purple}[DEBUG]#{Tty.reset} #{l.chomp!}"
        end
      end
    end

    # Prints a notice if in verbose mode.
    def blah notice
      return unless $VERBOSE
      puts notice.to_s
    end

    # Executes a command. Returns the output of the command.
    # Raises a Drupid::ErrorDuringExecution error if the command does not
    # exit successfully.
    #
    # [command] A String or Pathname object
    # [arguments] An optional Array of arguments
    # [options] An optional Hash of options
    #
    # Options: out, err, redirect_stderr_to_stdout, dry
    def runBabyRun command, arguments = [], options = {}
      opts = { :dry => false }.merge!(options)
      cmd = String.new(command.to_s)
      raise "Not an array" unless arguments.is_a?(Array)
      args = arguments.map { |arg| arg.to_s }
      cmd << ' '     + args.shelljoin
      cmd << ' >'    + Shellwords.shellescape(opts[:out]) if opts[:out]
      cmd << ' 2>'   + Shellwords.shellescape(opts[:err]) if opts[:err]
      cmd << ' 2>&1' if opts[:redirect_stderr_to_stdout]
      debug "Pwd: #{Dir.pwd}"
      debug cmd
      return cmd if opts[:dry]
      output = %x|#{cmd}| # Run baby run!
      unless $?.success?
        debug 'Command failed', output
        raise ErrorDuringExecution, output
      end
      return output
    end

    def curl *args
      curl = Pathname.new(which 'curl')
      args = ['-qf#LA', DRUPID_USER_AGENT, *args]
      args << "--insecure" #if MacOS.version < 10.6
      args << "--silent" unless $VERBOSE

      runBabyRun curl, args
    end

    def git *args
      git = Pathname.new(which 'git')
      raise "git not found" unless git.exist?
      raise "git is not executable" unless git.executable?
      runBabyRun git, args, :redirect_stderr_to_stdout => true
    end

    def svn *args
      svn = Pathname.new(which 'svn')
      raise "svn not found" unless svn.exist?
      raise "svn is not executable" unless svn.executable?
      runBabyRun svn, args, :redirect_stderr_to_stdout => true
    end

    def cvs *args
      cvs = Pathname.new(which 'cvs')
      raise "cvs not found" unless cvs.exist?
      raise "cvs is not executable" unless cvs.executable?
      runBabyRun cvs, args, :redirect_stderr_to_stdout => true
    end

    def hg *args
      hg = Pathname.new(which 'hg')
      raise "hg not found" unless hg.exist?
      raise "hg is not executable" unless hg.executable?
      runBabyRun hg, args, :redirect_stderr_to_stdout => true   
    end

    def bzr *args
      bzr = Pathname.new(which 'bzr')
      raise "bzr not found" unless bzr.exist?
      raise "bzr is not executable" unless bzr.executable?
      runBabyRun bzr, args, :redirect_stderr_to_stdout => true    
    end

    # Uncompresses an archive in the current directory.
    # [archive] A Pathname object representing the full path to the archive.
    # The the :type options is used, the archive is interpreted as the given
    # type (:zip, :gzip, :bzip2, :compress, :tar, :xz, :rar), otherwise
    # the type is guessed based on the file content.
    #
    # Options: type
    def uncompress archive, options = {}
      type = options[:type] ? options[:type] : archive.compression_type
      case type
      when :zip
        runBabyRun 'unzip', ['-qq', archive]
      when :gzip, :bzip2, :compress, :tar
        # Assume these are also tarred
        # TODO check if it's really a tar archive
        runBabyRun 'tar', ['xf', archive]
      when :xz
        runBabyRun "xz -dc \"#{archive}\" | tar xf -"
      when :rar
        runBabyRun 'unrar', ['x', '-inul', archive]
      else
        raise NotAnArchiveError
      end
    end

    # Creates a temporary directory then yield. When the block returns,
    # recursively delete the temporary directory.
    def tempdir
      # I used /tmp rather than `mktemp -td` because that generates a directory
      # name with exotic characters like + in it, and these break badly written
      # scripts that don't escape strings before trying to regexp them :(

      # If the user has FileVault enabled, then we can't mv symlinks from the
      # /tmp volume to the other volume. So we let the user override the tmp
      # prefix if they need to.
      tmp_prefix = '/tmp'
      tmp = Pathname.new `mktemp -d #{tmp_prefix}/temp_item-XXXXXX`.strip
      raise "Couldn't create temporary directory" if not tmp.directory? or $? != 0
      begin
        wd = Dir.pwd
        FileUtils.chdir tmp
        yield
      ensure
        FileUtils.chdir wd
        tmp.rmtree
      end
    end

    # Compares the content of two directories using rsync.
    # Changes in timestamps only are ignored.
    # Returns a possibly empty list of differences.
    def compare_paths src, tgt, additional_rsync_options = []
      p1 = Pathname.new(src).realpath.to_s + '/'
      p2 = Pathname.new(tgt).realpath.to_s + '/'
      args = Array.new
      args << '-rlD'
      args << '--dry-run'
      args << '--delete'
      args << '--itemize-changes'
      args += additional_rsync_options
      args << p1
      args << p2
      output = runBabyRun 'rsync', args, :verbose => false
      changes = Array.new
      output.each_line do |l|
        next if l =~ /[fdLDS]\.\.[tT]\.\.\.\./ # Skip changes in timestamps only
        changes << l.strip
      end
      return changes
    end

    def which cmd
      path = `which #{cmd} 2>/dev/null`.chomp
      path.empty? ? nil : Pathname.new(path)
    end

    def ignore_interrupts
      std_trap = trap("INT") {}
      yield
    ensure
      trap("INT", std_trap)
    end

    def interactive_shell
      fork {exec ENV['SHELL'] }
      Process.wait
      unless $?.success?
        owarn "Non-zero exit status: #{$?}"
      end
    end

    # Creates the specified file with the given content.
    # The file is overwritten if it exists.
    def writeFile path, content
      p = Pathname.new(path)
      blah "Writing #{p}"
      p.open("w") { |f| f.write(content) }
    end

  end # Utils
end # Drupid

