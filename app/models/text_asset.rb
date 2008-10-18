class TextAsset < ActiveRecord::Base
  set_inheritance_column :class_name

  order_by 'filename'

  # Associations
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'
  has_one :dependencies, :class_name => 'TextAssetDependencies', :dependent => :destroy

  validates_presence_of :filename, :message => 'required'
  validates_length_of :filename, :maximum => 100, :message => '%d-character limit'
  validates_uniqueness_of :filename, :scope => :class_name, :message => 'filename already in use'
  # the following regexp uses \A and \Z rather than ^ and $ to enforce no "\n" characters
  validates_format_of :filename, :with => %r{\A[-_.A-Za-z0-9]*\Z}, :message => 'invalid format'

  include Radiant::Taggable
  class TagError < StandardError; end


  def after_initialize
    self.dependencies = TextAssetDependencies.new(:list => []) if new_record?
    create_tag #adds the tag to the inherited class now that it has initialized
  end


  def url
    StylesNScripts::Config["#{self.class.to_s.underscore}_directory"] +
        "/" + self.filename
  end


  def effectively_updated_at
    dependencies.effectively_updated_at
  end


  def render
    text = self.content
    text = parse(text)
  end


  def parse(text, show_errors = true)
    unless @parser and @context
      @context = TextAssetContext.new(self)
      @parser = Radius::Parser.new(@context, :tag_prefix => 'r')
    end
    @context.show_errors = show_errors
    @parser.parse(text)
  end


  private

    # Adds a tag named after the inheriting class name (so <r:javascript> or
    # <r:stylesheet>.  This method is kind of funky since we wanted to define
    # the tag in only one place yet we don't have the inheriting class' name
    # until after initialization.
    def create_tag
      self.class.class_eval do
        tag(self.name.underscore) do |tag|
          if name = tag.attr['name']
            self.dependencies.list << tag.attr['name'].strip
            if text_asset = self.class.find_by_filename(tag.attr['name'].strip)
              text_asset.render
            else
              raise TagError.new("#{self.class.to_s.underscore} not found")
            end
          else
            raise TagError.new("`#{self.class.to_s.underscore}' tag must contain a `name' attribute.") unless tag.attr.has_key?('name')
          end
        end
      end
    end

end