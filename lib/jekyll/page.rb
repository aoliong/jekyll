# frozen_string_literal: true

module Jekyll
  class Page < Document
    attr_writer :dir
    attr_accessor :pager
    attr_accessor :name, :ext, :basename
    attr_writer :data

    alias_method :extname, :ext

    # NOTE: COMPATIBILITY
    #
    # Attributes for Liquid templates
    ATTRIBUTES_FOR_LIQUID = %w(
      content
      dir
      name
      path
      url
    ).freeze

    # A set of extensions that are considered HTML or HTML-like so we
    # should not alter them,  this includes .xhtml through XHTM5.
    HTML_EXTENSIONS = %w(
      .html
      .xhtml
      .htm
    ).freeze

    # Initialize a new Page.
    #
    # site - The Site object.
    # base - The String path to the source.
    # dir  - The String path between the source and the file.
    # name - The String filename of the file.
    def initialize(site, base, dir, name)
      @base = base
      @dir  = dir
      @name = name

      full_path = site.in_source_dir(base, dir, name)
      super(full_path, {
        :site       => site,
        :collection => site.pages,
      })

      process(@name)
      read(:path => full_path)
    end

    # NOTE: COMPATIBILITY
    #
    # The generated directory into which the page will be placed
    # upon generation. This is derived from the permalink or, if
    # permalink is absent, will be '/'
    #
    # Returns the String destination directory.
    def dir
      if url.end_with?("/")
        url
      else
        url_dir = File.dirname(url)
        url_dir.end_with?("/") ? url_dir : "#{url_dir}/"
      end
    end

    # The template of the permalink.
    #
    # Returns the template String.
    def url_template
      if !html?
        "/:path/:basename:output_ext"
      elsif index?
        "/:path/"
      else
        Utils.add_permalink_suffix("/:path/:basename", site.permalink_style)
      end
    end

    # Returns a hash of URL placeholder names (as symbols) mapping to the
    # desired placeholder replacements. For details see "url.rb"
    def url_placeholders
      {
        :path       => @dir,
        :basename   => basename,
        :output_ext => output_ext,
      }
    end

    # Extract information from the page filename.
    #
    # name - The String filename of the page file.
    #
    # Returns nothing.
    def process(name)
      self.ext = File.extname(name)
      self.basename = name[0..-ext.length - 1]

      # Invalidate URL
      @url = nil
      url
    end

    # NOTE: COMPATIBILITY
    #
    # Render the page
    def render(_layouts, site_payload)
      self.output = Jekyll::Renderer.new(@site, self, site_payload).run
    end

    # NOTE: COMPATIBILITY
    #
    # The path to the source file
    #
    # Returns the path to the source file
    def path
      data.fetch("path") { relative_path }
    end

    # Compatiblity
    #
    # The path to the page source file, relative to the site source
    def relative_path
      File.join(*[@dir, @name].map(&:to_s).reject(&:empty?)).sub(%r!\A\/!, "")
    end

    # NOTE: COMPATIBILITY
    #
    # Obtain destination path.
    #
    # dest - The String path to the destination dir.
    #
    # Returns the destination file path String.
    def destination(dest)
      path = site.in_dest_dir(dest, URL.unescape_path(url))
      path = File.join(path, "index") if url.end_with?("/")
      path << output_ext unless path.end_with? output_ext
      path
    end

    # NOTE: COMPATIBILITY
    #
    # Returns the object as a debug String.
    def inspect
      "#<Jekyll::Page @name=#{name.inspect}>"
    end

    # Returns the Boolean of whether this Page is HTML or not.
    def html?
      HTML_EXTENSIONS.include?(output_ext)
    end

    # Returns the Boolean of whether this Page is an index file or not.
    def index?
      basename == "index"
    end

    def trigger_hooks(hook_name, *args)
      Jekyll::Hooks.trigger :pages, hook_name, self, *args
    end

    # Don't generate excerpts for pages
    def generate_excerpt?
      false
    end

    # Determine whether the file should be rendered with Liquid.
    #
    # Always returns true.
    def render_with_liquid?
      true
    end

    # Don't generate a title
    def post_read
      original = data["title"]
      super
      data["title"] = original
    end

    # NOTE: COMPATIBILITY
    #
    # Accessor for data properties by Liquid.
    #
    # property - The String name of the property to retrieve.
    #
    # Returns the String value or nil if the property isn't included.
    def [](property)
      if ATTRIBUTES_FOR_LIQUID.include?(property)
        public_send(property)
      else
        data[property]
      end
    end
  end
end
