require File.dirname(__FILE__) + '/../spec_helper'

describe UserActionObserver do
  scenario :users, :stylesheets, :javascripts
  
  before(:each) do
    @user = users(:existing)
    UserActionObserver.current_user = @user
  end


  it 'should observe stylesheet creation' do
    Stylesheet.create!(stylesheet_params).created_by.should == @user
  end

  
  it 'should observe javascript creation' do
    Javascript.create!(javascript_params).created_by.should == @user
  end


  it 'should observe stylesheet update' do
    model = Stylesheet.find_by_filename('main.css')
    model.attributes = model.attributes.dup
    model.save.should == true
    model.updated_by.should == @user
  end

  
  it 'should observe javascript update' do
    model = Javascript.find_by_filename('main.js')
    model.attributes = model.attributes.dup
    model.save.should == true
    model.updated_by.should == @user
  end

end