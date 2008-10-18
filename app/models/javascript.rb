class Javascript < TextAsset

  class TagError < StandardError; end
  
  tag('javascript') do |tag|
    if name = tag.attr['name']
      self.dependencies << tag.attr['name'].strip
      if javascript = Javascript.find_by_filename(tag.attr['name'].strip)
        javascript.render
      else
        raise TagError.new("javascript not found")
      end
    else
      raise TagError.new("`javascript' tag must contain a `name' attribute.") unless tag.attr.has_key?('name')
    end
  end 

end