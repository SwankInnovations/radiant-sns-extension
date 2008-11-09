# This specs the behavior of the Stylesheet and Javascript models where they
# share much the same behavior (this is better than spec-ing the TextAsset model
# since, frankly, we care about the Stylesheet and Javascript models, not their
# parent).
#
# In the future, should unique behaviors appear, they would go at the bottom of
# this spec or in their own specs.

require File.dirname(__FILE__) + '/../spec_helper'

[ Stylesheet, Javascript].each do |current_asset|
  describe current_asset do

    before(:each) do
      @record = current_asset.new
    end


    it 'should limit the name to 100 characters' do
      @record.name = 'a' * 100
      @record.should be_valid

      @record.name = 'a' * 101
      @record.should_not be_valid
    end


    it 'should not allow an empty name' do
      @record.name = ''
      @record.should_not be_valid
    end


    it 'should require unique names (within same subclass)' do
      @record.name = 'abc.123'
      @record.save!

      @invalid_record = current_asset.new(:name => 'abc.123')
      @invalid_record.should_not be_valid
      @invalid_record.should have(1).error_on(:name)
      @invalid_record.errors.on(:name).should == 'name already in use'
    end


    it 'should permit the same name as a stylesheet and javascript' do
      @record.name = 'abc.123'
      @record.save!

      if current_asset == Stylesheet
        @record_of_other_subclass = Javascript.new(:name => 'abc.123')
      elsif current_asset == Javascript
        @record_of_other_subclass = Stylesheet.new(:name => 'abc.123')
      end
      @record_of_other_subclass.should be_valid
    end


    it 'should allow names with alphanumeric chars, underscores, periods, & hyphens' do
      @record.name = 'abc'
      @record.should be_valid

      @record.name = 'ABC'
      @record.should be_valid

      @record.name = 'Abc123'
      @record.should be_valid

      @record.name = 'aBc.123'
      @record.should be_valid

      @record.name = 'aBc_123'
      @record.should be_valid

      @record.name = 'aBc-123'
      @record.should be_valid

      @record.name = 'a.B-c.1_2-3'
      @record.should be_valid
    end


    # declare an array of invalid characters then iterate through each and test
    (
      %w[! @ # $ % ^ & * ( ) { } \ / < > + = ? , : ; ' "] +
      [' ', "\t", "\n", "\r", '[', ']']
    ).each do |invalid_char|
      it "should not allow names with invalid characters (#{invalid_char.inspect})" do
        @record.name = "abc#{invalid_char}123"
        @record.should_not be_valid
        @record.should have(1).error_on(:name)
        @record.errors.on(:name).should == 'invalid format'
      end
    end


    it 'should automatically sort by name' do
      @record.name = 'a_is_for_apple'
      @record.save!

      @record = current_asset.new
      @record.name = 'j_is_for_jacks'
      @record.save!

      @record = current_asset.new
      @record.name = 'c_is_for_chocolate_frosted_sugar_bombs'
      @record.save!

      current_asset.find(:all).should == current_asset.find(:all).sort_by { |item| item[:name] }
    end

  end
end