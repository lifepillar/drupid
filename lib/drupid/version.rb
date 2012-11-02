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

  class NotDrupalVersionError < RuntimeError
  end

  # Represents the core attribute of a version object (e.g., '7.x').
  # A VersionCore object can be initialized from a number, a string,
  # a Drupid::VersionCore object or a Drupid::Version object.
  #
  # Examples:
  #  core = Drupid::VersionCore.new '8.x'
  #  core = Drupid::VersionCore.new '8'
  #  core = Drupid::VersionCore.new '8.x-1.0'
  #  core = Drupid::VersionCore.new 8
  #  core = Drupid::VersionCore.new(Drupid::Version.new(8, '1.0'))
  class VersionCore
    include Comparable

    attr :core

    def initialize spec
      if spec.is_a?(String)
        spec.strip.match(/^(\d+)(\.x)?($|-)/)
        raise NotDrupalVersionError, "Wrong core specification: #{core}" unless $1
        @core = $1.to_i
      elsif spec.is_a?(Version)
        @core = spec.core.to_i
      elsif spec.is_a?(VersionCore)
        @core = spec.to_i
      elsif spec.is_a?(Numeric)
        @core = spec.to_i # to_i truncates a Float object (so that 7.9 correctly becomes 7)
      else
        raise NotDrupalVersionError, "Wrong core specification: #{core}"
      end
    end

    # Returns the core number as a string, e.g., '8.x'.
    def to_s
      @core.to_s + '.x'
    end

    # Returns the core number as a Fixnum object.
    def to_i
      @core
    end

    def <=>(other)
      @core <=> other.core
    end
  end

  # Represents a project's version. A version has the form:
  #   <core>.x-<major>.<patch level>[-<extra>]
  # Examples of versions include: '7.x-1.0', '7.x-1.2-beta2', '8.x-1.x-dev'.
  #
  # See also: http://drupal.org/node/467026
  class Version
    include Comparable
    # The core number, e.g., in 7.x-3.2.beta1, it is 7.
    attr :core
    # The major version number, e.g., in 7.x-3.2-beta1, it is 3 (Fixnum).
    attr :major
    # The patch level, e.g., in 7.x-3.2-beta1, it is 2 (Fixnum).
    attr :patchlevel
    # The project's type, which is one of the constants UNSTABLE,
    # ALPHA, BETA, RC, DEVELOPMENT, EMPTY or UNKNOWN.
    # For example, for 7.x-3.2-beta1, it is BETA.
    attr :extra_type
    # The numeric part of the extra description, e.g., 7.x-3.2-beta1, it is 1 (Fixnum).
    attr :extra_num

    UNKNOWN     = -1
    DEVELOPMENT = 1
    UNSTABLE    = 2
    ALPHA       = 4
    BETA        = 8
    RC          = 16
    EMPTY       = 32

    def initialize(core_num, v)
      raise 'Drupal version is not a string.' unless v.is_a?(String)
      @core = Drupid::VersionCore.new(core_num)
      @major = v.match(/^(\d+)/)[1].to_i
      @patchlevel = $~.post_match.match(/\.(\d+|x)/)[1]
      @patchlevel = @patchlevel.to_i if 'x' != @patchlevel
      @extra_string = ''
      encode_extra($~.post_match) # Initialize @extra_type and @extra_num
    end

    # Builds a Drupid::Version object from a string, e.g., '8.x-2.0rc1'.
    def self.from_s v
      if v.match(/^(\d+)\.x-(\d+.+)$/)
        Version.new($1.to_i, $2)
      else
        raise NotDrupalVersionError, "Cannot build a version from this string: #{v}"
      end
    end

    # Returns true if this version represents a development snapshot;
    # returns false otherwise.
    def development_snapshot?
      'x' == @patchlevel
    end

    # A synonym for self.short.
    def to_s
      short
    end

    # Returns a short textual representation of this version, e.g., '3.2'.
    def short
      xtr = extra()
      xtr = '-' + xtr if '' != xtr
      @major.to_s + '.' + @patchlevel.to_s + xtr
    end

    # Returns the full textual representation of this version, e.g., '7.x-3.2'.
    def long
      xtr = extra()
      xtr = '-' + xtr if '' != xtr
      @core.to_s + '-' + @major.to_s + '.' + @patchlevel.to_s + xtr
    end

    # In Ruby 1.8.7, some equality tests fail with the following message:
    #   No visible difference.
    #   You should look at your implementation of ==.
    # if only <=> is defined. This is why we define == explicitly.
    def ==(other)
      @core == other.core and
      @major == other.major and
      @patchlevel == other.patchlevel and
      @extra_type == other.extra_type and
      @extra_num == other.extra_num
    end

    def <=>(w)
      c = @core <=> w.core
      if 0 == c
        c = @major <=> w.major
        if 0 == c
          c = @patchlevel <=> w.patchlevel
          case c
          when nil # e.g., 1 vs 'x'
            c = ('x' == @patchlevel) ? -1 : 1
          when 0
            c = @extra_type <=> w.extra_type
            if 0 == c
              c = @extra_num <=> w.extra_num
            end
          end
        end
      end
      c
    end

    def extra
      case @extra_type
        when EMPTY then t = ''
        when UNSTABLE then t = 'unstable'
        when ALPHA then t = 'alpha'
        when BETA then t = 'beta'
        when RC then t = 'rc'
        when DEVELOPMENT then t = 'dev'
      else # unknown
        t = @extra_string
      end
      if UNKNOWN == @extra_num
        t
      else
        t + @extra_num.to_s
      end
    end

    private

    def encode_extra(e)
      @extra_string = e.start_with?('-') ? e.sub(/-/, '') : e
      if e.match(/dev(\d*)$/)
        @patchlevel = 'x'
        @extra_type = DEVELOPMENT
        @extra_num = ($~[1] == '') ? UNKNOWN : $~[1].to_i
        return
      end
      e.match(/^-{0,1}([A-z]*)(\d*)$/)
      if nil != $~
        t = $~[1]
        n = $~[2]
        case t
        when /^$/       then @extra_type = EMPTY
        when /dev/      then @extra_type = DEVELOPMENT
        when /unstable/ then @extra_type = UNSTABLE
        when /alpha/    then @extra_type = ALPHA
        when /beta/     then @extra_type = BETA
        when /rc/       then @extra_type = RC
        else
          @extra_type = UNKNOWN
        end
        @extra_num = ('' != n) ? n.to_i : UNKNOWN
      else
        @extra_type = UNKNOWN
        @extra_num = UNKNOWN
      end
      return
    end

  end # class Version

end # Drupid
