module Sns
  module PageTags
    include Radiant::Taggable
    class TagError < StandardError; end

    [ { :name => 'stylesheet',
        :class => Stylesheet,
        :inline_tag => 'style',
        :link_tag => 'link',
        :sample_file => 'my_file.css' },

      { :name => 'javascript',
        :class => Javascript,
        :inline_tag => 'script',
        :link_tag => 'script',
        :sample_file => 'my_file.js' }

    ].each do |current_tag|
      desc %{
      Renders the content from or a reference to the #{current_tag[:name]}
      specified in the @name@ attribute. Additionally, the @as@ attribute can be
      used to make the tag render as one of the following:

        * @content@ - renders the #{current_tag[:name]}'s content (this is the
          default when the @as@ attribute is omitted).

        * @inline@ - wraps the #{current_tag[:name]}'s content in an (X)HTML
          @<#{current_tag[:inline_tag]}>@ element.

        * @url@ - the url to the #{current_tag[:name]} (relative to the web root).

        * @link@ - embeds the url in an (X)HTML @<#{current_tag[:link_tag]}>@
          element (creating a link to the external #{current_tag[:name]}).


      *Additional Options:*
      When rendering @as@="@inline@" or @as@="@link@", the (X)HTML @type@ attribute
      is automatically be set to the default #{current_tag[:name]} content-type.
      You can overrride this attribute or add additional ones by passing extra
      attributes to the @<r:#{current_tag[:name]}>@ tag. For example,
      <pre><code><r:#{current_tag[:name]} name="#{current_tag[:sample_file]}" as="inline" type="text/custom" id="my_id" /> produces...

  <#{current_tag[:inline_tag]} type="text/custom" id="my_id">
  //<![CDATA[
    Your #{current_tag[:name]}'s content here...
  //]]>
  </#{current_tag[:inline_tag]}></code></pre>

        *Usage:*
        <pre><code><r:#{current_tag[:name]} name="#{current_tag[:sample_file]}" [as="content | inline | url | link"] [other attribues...] /></code></pre>
      }
      tag(current_tag[:name]) do |tag|
        if name = tag.attr['name']
          if text_asset = current_tag[:class].find_by_name(tag.attr['name'].strip)
            case tag.attr['as']
              when 'content', nil
                text_asset.render

              when 'url'
                text_asset.url

              when 'inline', 'link'
                mime_type = tag.attr['type'] || Sns::Config["#{current_tag[:name]}_mime_type"]
                optional_attribs = tag.attr.except('name', 'as', 'type').inject('') { |s, (k, v)| s << %{#{k.downcase}="#{v}" } }.strip
                optional_attribs = " #{optional_attribs}" unless optional_attribs.empty?

                if tag.attr['as'] == 'inline'
                  %{<#{current_tag[:inline_tag]} type="#{mime_type}"#{optional_attribs}>\n//<![CDATA[\n#{text_asset.render}\n//]]>\n</#{current_tag[:inline_tag]}>}

                elsif tag.attr['as'] == 'link' && current_tag[:name] == 'stylesheet'
                  %{<link rel="stylesheet" href="#{text_asset.url}" type="#{mime_type}"#{optional_attribs} />}

                elsif tag.attr['as'] == 'link' && current_tag[:name] == 'javascript'
                  %{<script src="#{text_asset.url}" type="#{mime_type}"#{optional_attribs}></script>}

                end
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
end