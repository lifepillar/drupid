require 'kramdown'
require 'zurb-foundation'

set :markdown_engine, :kramdown
set :md, :layout_engine => :erb

ignore "blog/*"
ignore "javascripts/foundation/*"
ignore "javascripts/foundation.js.coffee"
ignore "javascripts/vendor/jquery.js"
ignore "javascripts/vendor/zepto.js"

###
# Compass
###

# Susy grids in Compass
# First: gem install susy
# require 'susy'

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false

page 'robots.txt', :layout => false
page 'humans.txt', :layout => false

# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy (fake) files
# page "/this-page-has-no-template.html", :proxy => "/template-file.html" do
#   @which_fake_page = "Rendering a fake page with a variable"
# end

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

set :build_dir, 'public'
set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript

  # Minify HTML on build
  activate :minify_html

  # Use relative URLs
  activate :relative_assets

  # Enable cache buster
  # activate :cache_buster

  # Use relative URLs
  # activate :relative_assets

  # Compress PNGs after build
  # First: gem install middleman-smusher
  # require "middleman-smusher"
  # activate :smusher

  # Or use a different image path
  # set :http_path, "/Content/images/"
end

# Middleman Blog
# Time.zone = "UTC"
# activate :blog do |blog|
#   blog.prefix = "/blog"
#   blog.permalink = ":year/:month/:day/:title.html"
#   blog.sources = ":year-:month-:day-:title.html"
#   blog.taglink = "tags/:tag.html"
#   blog.layout = "article"
#   blog.summary_separator = /(READMORE)/
#   blog.summary_length = 250
#   blog.year_link = ":year.html"
#   blog.month_link = ":year/:month.html"
#   blog.day_link = ":year/:month/:day.html"
#   blog.default_extension = ".md"

#   blog.tag_template = "/blog/tag.html"
#   blog.calendar_template = "/blog/calendar.html"

#   blog.paginate = true
#   blog.per_page = 5
#   blog.page_link = "page/:num"
# end

page "/blog/feed.xml", :layout => false

# Middleman Deploy
activate :deploy do |deploy|
  deploy.method = :git
  deploy.remote = 'origin'
  deploy.branch = 'gh-pages'
end

activate :directory_indexes
page "/404.html", :directory_index => false

activate :syntax,
         :linenos => 'inline',
         :anchorlinenos => true,
         :linenostart => 2

activate :livereload