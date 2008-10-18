class Stylesheet < TextAsset

  class TagError < StandardError; end
  
  tag('stylesheet') do |tag|
    if name = tag.attr['name']
      self.dependencies << tag.attr['name'].strip
      if stylesheet = Stylesheet.find_by_filename(tag.attr['name'].strip)
        stylesheet.render
      else
        raise TagError.new("stylesheet not found")
      end
    else
      raise TagError.new("`stylesheet' tag must contain a `name' attribute.") unless tag.attr.has_key?('name')
    end
  end 

end