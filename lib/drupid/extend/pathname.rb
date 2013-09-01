# -*- coding: ascii -*-

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

# Code borrowed from Homebrew ;)
class Pathname
  def compression_type
    return nil if self.directory?
    # Don't treat jars or wars as compressed
    return nil if self.extname == '.jar'
    return nil if self.extname == '.war'
  
    # OS X installer package
    return :pkg if self.extname == '.pkg'
  
    # Get enough of the file to detect common file types
    # POSIX tar magic has a 257 byte offset
    magic_bytes = nil
    File.open(self) { |f| magic_bytes = f.read(262) }
  
    # magic numbers stolen from /usr/share/file/magic/
    case magic_bytes
    when /^PK\003\004/   then :zip
    when /^\037\213/     then :gzip
    when /^BZh/          then :bzip2
    when /^\037\235/     then :compress
    when /^.{257}ustar/  then :tar
    when /^\xFD7zXZ\x00/ then :xz
    when /^Rar!/         then :rar
    else
      # Assume it is not an archive
      nil
    end
  end

  def cd
    Dir.chdir(self) { yield }
  end

  # Copies a file to another location or
  # the content of a directory into the specified directory.
  def ditto dst
    d = Pathname.new(dst)
    if file?
      FileUtils.cp to_s, d.to_s, :verbose => $DEBUG
      return (d.directory?) ? d+basename : d
    else
      d.mkpath
      FileUtils.cp_r to_s + '/.', d.to_s, :verbose => $DEBUG
      return d
    end
  end

  # extended to support common double extensions
  alias extname_old extname
  def extname
    /(\.(tar|cpio)\.(gz|bz2|xz|Z))$/.match to_s
    return $1 if $1
    return File.extname(to_s)
  end

  # Pathname in Ruby 1.8.x does not define #sub_ext.
  unless self.method_defined? :sub_ext
    # Return a pathname which the extension of the basename is substituted by
    # <i>repl</i>.
    #
    # If self has no extension part, <i>repl</i> is appended.
    def sub_ext(repl)
      ext = File.extname(@path)
      self.class.new(@path.chomp(ext) + repl)
    end
  end
end # Pathname
