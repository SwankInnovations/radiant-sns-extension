module FileSystem::Model::TextAssetExtensions
  
  def self.included(base)
    base.class_eval do
      extend ClassMethods
    end
  end
  
  module ClassMethods
    
    def load_files
      files = Dir[path + "/**"]
      unless files.blank?
        records_on_filesystem = []
        files.each do |file|
          record = find_or_initialize_by_filename(File.basename(file))
          puts "Loading #{self.name.downcase} from #{File.basename(file)}"
          record.load_file(file)
          record.save
          records_on_filesystem << record
        end
        fileless_db_records = records_on_database - records_on_filesystem
        fileless_db_records.each { |item| delete_record(item) }
      end
    end
    
    
    def extract_name(basename)
      name_parts = basename.split(".")
      type_or_filter = name_parts.pop
      name_parts.pop if name_parts[-1] == "min"
      name = name_parts.join(".")
    end
  end
  
  def load_file(file)
    name, mini, type_or_filter = extract_attrs_from_filename(File.basename(file))
    content = open(file).read
    self.name = name
    self.content = content
    if respond_to?(:filter_id)
      self.filter_id = filters.include?(type_or_filter) ? type_or_filter.camelize : nil
    end
    if respond_to?(:minify)
      self.minify = mini
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