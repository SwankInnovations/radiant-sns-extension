class TextAsset < ActiveRecord::Base
  set_inheritance_column :class_name

  # Default Order
  order_by 'filename'
  
  # Associations
  belongs_to :created_by, :class_name => 'User'
  belongs_to :updated_by, :class_name => 'User'

  validates_presence_of :filename, :message => 'required'
  validates_length_of :filename, :maximum => 100, :message => '%d-character limit'
  validates_uniqueness_of :filename, :scope => :class_name, :message => 'filename already in use'
  # the following regexp uses \A and \Z rather than ^ and $ to enforce no "\n" characters
  validates_format_of :filename, :with => %r{\A[-_.A-Za-z0-9]*\Z}, :message => 'invalid format'

  def url
    StylesNScripts::Config["#{self.class.to_s.underscore}_directory"] +
        "/" + self.filename
  end

end
