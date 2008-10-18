require File.dirname(__FILE__) + '/../spec_helper'

[ CssAsset, JsAsset].each do |current_asset|
  describe current_asset do
  
    before(:each) do
      @record = current_asset.new
    end
  

    it 'should limit the filename to 100 characters' do
      @record.filename = 'a' * 100
      @record.should be_valid
      
      @record.filename = 'a' * 101
      @record.should_not be_valid
    end


    it 'should not allow an empty filename' do
      @record.filename = ''
      @record.should_not be_valid
    end


    it 'should require unique filenames (within same subclass)' do
      @record.filename = 'abc.123'
      @record.save!

      @invalid_record = current_asset.new(:filename => 'abc.123')
      @invalid_record.should_not be_valid
      @invalid_record.should have(1).error_on(:filename)
      @invalid_record.errors.on(:filename).should == 'filename already in use'
    end


    it 'should permit the same filename across different subclasses' do
      @record.filename = 'abc.123'
      @record.save!

      if current_asset == CssAsset
        @record_of_other_subclass = JsAsset.new(:filename => 'abc.123')
      elsif current_asset == JsAsset
        @record_of_other_subclass = CssAsset.new(:filename => 'abc.123')      
      end
      @record_of_other_subclass.should be_valid
    end


    it 'should allow filenames with alphanumeric chars, underscores, periods, & hyphens' do
      @record.filename = 'abc'
      @record.should be_valid

      @record.filename = 'ABC'
      @record.should be_valid

      @record.filename = 'Abc123'
      @record.should be_valid

      @record.filename = 'aBc.123'
      @record.should be_valid

      @record.filename = 'aBc_123'
      @record.should be_valid

      @record.filename = 'aBc-123'
      @record.should be_valid

      @record.filename = 'a.B-c.1_2-3'
      @record.should be_valid
    end


    # declare an array of invalid characters then iterate through each and test
    (
      %w[! @ # $ % ^ & * ( ) { } \ / < > + = ? , : ; ' "] + 
      [' ', "\t", "\n", "\r", '[', ']']
    ).each do |invalid_char|
      it "should not allow filenames with invalid characters (#{invalid_char.inspect})" do
        @record.filename = "abc#{invalid_char}123"
        @record.should_not be_valid
        @record.should have(1).error_on(:filename)
        @record.errors.on(:filename).should == 'invalid format' 
      end
    end


  it 'should yeild the same output for #content and #raw_content methods' do
    @record.filename = "valid.filename"
    @record.raw_content = "my raw content"
    @record.content.should == "my raw content"
  end

  end
end