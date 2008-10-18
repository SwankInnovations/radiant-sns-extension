class TextAsset < ActiveRecord::Base
  set_inheritance_column :class_name

  order_by 'filename'
  
  # Associations
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'

  validates_presence_of :filename, :message => 'required'
  validates_length_of :filename, :maximum => 100, :message => '%d-character limit'
  validates_uniqueness_of :filename, :scope => :class_name, :message => 'filename already in use'
  # the following regexp uses \A and \Z rather than ^ and $ to enforce no "\n" characters
  validates_format_of :filename, :with => %r{\A[-_.A-Za-z0-9]*\Z}, :message => 'invalid format'

  include Radiant::Taggable

  serialize :dependencies, Array
  before_save :update_dependencies

  # for some reason setting dependencies to serialize as Array still lets this
  # value be nil.  AR should do this step for me.  Oh well.
  def after_initialize
    self.dependencies = [] if dependencies.nil?
  end

#  after_save :effectively_updated_at

  def url
    StylesNScripts::Config["#{self.class.to_s.underscore}_directory"] +
        "/" + self.filename
  end

  
  def update_dependencies
    self.dependencies = []
    parse(content, false)
    self.dependencies.uniq!
  end

  
  def effectively_updated_at
    if self.dependencies.empty?
      self.updated_at
    else
      dependency_assets = self.class.find_all_by_filename(self.dependencies).compact
      dependencies_last_updated_at = dependency_assets.sort_by{|i| i[:updated_at]}.last.updated_at
      puts dependencies_last_updated_at.to_s
    end
  end


#  def update_dependents_timestamps()
#    self.class.find(:all).each do |text_asset|
#      unless text_asset.dependencies.nil?
#        if text_asset.dependencies.include?(filename)
#          puts "updating #{text_asset.filename} to dependencies_updated_at: #{updated_at}"
#          text_asset.dependencies_updated_at = updated_at
#          TextAsset.record_timestamps = false
#          text_asset.save
#          TextAsset.record_timestamps = true
#        end
#      end
#    end
#  end

  def render
    text = self.content
    text = parse(text)
  end


  private

    def parse(text, show_errors = true)
      unless @parser and @context
        @context = TextAssetContext.new(self)
        @parser = Radius::Parser.new(@context, :tag_prefix => 'r')
      end
      @context.show_errors = show_errors
      @parser.parse(text)
    end

end
