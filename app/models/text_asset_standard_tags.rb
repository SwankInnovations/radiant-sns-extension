module TextAssetStandardTags

  class TagError < StandardError; end

  def self.included(base)
    base.class_eval do
     
      # declares the <r:stylesheet /> OR <r:javascript /> tag depending on the
      # class type of base.
      tag_name = base.name.to_s.underscore
      tag tag_name do |tag|
        if name = tag.attr['name']
          if named_asset = base.find_by_name(name.strip)
            named_asset.render
          else
            raise TagError.new("#{tag_name} with name `#{name}' not found")
          end
        else
          raise TagError.new("`#{tag_name}' tag must contain a `name' attribute.")
        end      
      end

    end
  end

end