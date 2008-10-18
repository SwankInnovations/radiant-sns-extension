module ExtendedPageTags
  include Radiant::Taggable
  class TagError < StandardError; end

  [ { :name => 'stylesheet',
      :class => Stylesheet,
      :inline_tag => 'style',
      :sample_file => 'my_file.css' },
      
    { :name => 'javascript',
      :class => Javascript,
      :inline_tag => 'script',
      :sample_file => 'my_file.js' }
  ].each do |current_tag|
    desc %{
      Renders the content from or url for a #{current_tag[:name]} asset.  The 
      @name@ attribute is required to identify the desired #{current_tag[:name]}.
      file. Additionally, the @as@ attribute can be used to choose whether to 
      render the tag as one of the following:

        * @content@ - the content of the #{current_tag[:name]} is rendered (this
          is the default).

        * @url@ - the url of the #{current_tag[:name]} file (relative to the
          web root).

        * @inline@ - same as @content@ but wraps the content in an (X)HTML
          &lt;#{current_tag[:inline_tag]}> element.  By default, the @type@
          attribute of the &lt;#{current_tag[:inline_tag]}> element will
          automatically match the default #{current_tag[:name]} content-type
         (but you can override this -- see Additional Options below).
      
      *Additional Options:*
      When rendering &lt;r:#{current_tag[:name]} @as@="inline" />, any
      additional attributes you provide will be passed on directly to the
      &lt;#{current_tag[:inline_tag]}> element, like:
      <pre><code><r:#{current_tag[:name]} name="#{current_tag[:sample_file]}" as="inline" id="my_id" type="text/custom" />
               produces:
      <#{current_tag[:inline_tag]} type="text/custom" id="my_id">
      <!--
        Your #{current_tag[:name]}'s content here...
      -->
      </#{current_tag[:inline_tag]}></code></pre>
     
      *Usage:* 
      <pre><code><r:#{current_tag[:name]} name="#{current_tag[:sample_file]}" [as="content | inline | url"] /></code></pre>
    }
    tag(current_tag[:name]) do |tag|
      if name = tag.attr['name']
        if text_asset = current_tag[:class].find_by_filename(tag.attr['name'].strip)
          case tag.attr['as']
            when 'content', nil
              text_asset.render
            when 'url'
              text_asset.url
            when 'inline'
              mime_type = tag.attr['type'] || StylesNScripts::Config["#{current_tag[:name]}_mime_type"]
              optional_attribs = tag.attr.except('name', 'as', 'type').inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
              optional_attribs = " #{optional_attribs}" unless optional_attribs.empty?
              %{<#{current_tag[:inline_tag]} type="#{mime_type}"#{optional_attribs}>\n<!--\n#{text_asset.render}\n-->\n</#{current_tag[:inline_tag]}>}
          end
        else
          raise TagError.new("#{current_tag[:name]} not found")
        end
      else
        raise TagError.new("`#{current_tag[:name]}' tag must contain a `name' attribute.") unless tag.attr.has_key?('name')
      end
    end
 
  end
end