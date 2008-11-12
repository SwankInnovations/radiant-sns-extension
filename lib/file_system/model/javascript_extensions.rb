module FileSystem::Model::JavascriptExtensions
  
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end
  
  module ClassMethods
    def klass_name
      "Javascript"
    end
  end
  
  def load_file(file)
    # filename_regex = /^(?:(\d+)_)?([^.]+)(?:\.([\-\w]+))?/
    # name, type_or_filter = $2, $3 if File.basename(file) =~ filename_regex
    # 
    # basename = File.basename(file)
    # name_parts = basename.count(".")
    # filename_regex = /([^.]+)#{"(?:\.([^.]+))?" * name_parts}/
    # if basename =~ filename_regex
    #   captures = Regexp.last_match.captures
    #   type_or_filter = captures.pop
    #   if captures[-1] == "min"
    #     min = true
    #     captures.pop
    #   end
    #   name = captures.join(".")
    # end
    
    name, mini, type_or_filter = extract_attrs_from_filename(File.basename(file))
    content = open(file).read
    self.name = name
    self.content = content
    if respond_to?(:filter_id) 
      self.filter_id = filters.include?(type_or_filter) ? type_or_filter.camelize : nil
    end
    if respond_to?(:minifiy)
      self.minifiy = mini
    end
  end
  
  def filename
    @filename ||= returning String.new do |output|
      basename = self.name
      extension = case 
        when respond_to?(:filter_id)
          self.filter_id.blank? ? default_content_type : self.filter_id.downcase
        when respond_to?(:content_type)
          CONTENT_TYPES.invert[self.content_type] || default_content_type
        else
          default_content_type
      end
      minify = case
        when respond_to?(:minify) 
          self.minify ? "min" : nil
        else nil
      end
      output << File.join(self.class.path, 
                          [basename, minify, extension].compact.join("."))
    end
  end
  
  private
    def default_content_type
      "js"
    end
    
    def extract_attrs_from_filename(basename)
      name_parts = basename.split(".")
      type_or_filter = name_parts.pop
      mini = false
      if name_parts[-1] == "min"
        mini = true
        name_parts.pop
      end
      name = name_parts.join(".")
      [name, mini, type_or_filter]
    end
  
end