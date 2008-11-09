# This specifies the dependency behaviors of Javascripts and Stylesheets (added
# in version 0.3).  These behaviors allow the text assets to track dependencies
# created by <r:stylesheet> or <r:javascript> tags when used in a text asset
# context and maintain an effectively_updated_at date to ensure proper caching
# of stylesheets and javascripts.

require File.dirname(__FILE__) + '/../spec_helper'

[ { :class => Stylesheet,
    :name => 'stylesheet',
    :default_mime_type => 'text/css',
    :inline_element => 'style' },

  { :class => Javascript,
    :name => 'javascript',
    :default_mime_type => 'text/javascript',
    :inline_element => 'script' }

].each do |current_tag|

  describe "During save, #{current_tag[:name].pluralize} containing <r:#{current_tag[:name]}> tags" do

    before :each do
      @text_asset = current_tag[:class].new(:name => 'dependant')
      @text_asset.content = %{<r:#{current_tag[:name]} name="main" />}
    end


    it 'should log one dependency if only one tag' do
      @text_asset.save!
      @text_asset.dependencies.list.should == ["main"]
    end


    it 'should log a dependency even if the reference file does not exist' do
      @text_asset.content = %{<r:#{current_tag[:name]} name="a_nonexistent_file" />}
      @text_asset.save!
      @text_asset.dependencies.list.should == ["a_nonexistent_file"]
    end


    it 'should log only one dependency if mulitiple tags all reference the the same file' do
      @text_asset.content << %{<r:#{current_tag[:name]} name="main" />}
      @text_asset.save!
      @text_asset.dependencies.list.should == ["main"]
    end


    it 'should log multiple dependencies if multiple files are referenced' do
      @text_asset.content << %{<r:#{current_tag[:name]} name="another_file" />}
      @text_asset.save!
      @text_asset.dependencies.list.sort.should == ["another_file", "main"]
    end


    it 'should log only each dependency only once' do
      @text_asset.content << %{<r:#{current_tag[:name]} name="another_file" />}
      @text_asset.content << %{<r:#{current_tag[:name]} name="main" />}
      @text_asset.save!
      @text_asset.dependencies.list.sort.should == ["another_file", "main"]
    end

  end




  describe "A saved #{current_tag[:name]}'s effectively_updated_at method" do
    before :each do
      @dependant = current_tag[:class].new(:name => 'dependant')
      save_asset_at(@dependant, 1990)
    end


    it "should reflect its own creation date/time (created_at) if the file hasn't been updated and has no dependencies" do
      @dependant.dependencies.effectively_updated_at.should == Time.gm(1990)
    end


    it "should reflect its own change date/time (updated_at) if the file has no dependencies" do
      save_asset_at(@dependant, 1994)
      @dependant.dependencies.effectively_updated_at.should == Time.gm(1994)
    end


    it "should reflect its own change date/time if it references dependencies which do not exist" do
      @dependant.content = %{<r:#{current_tag[:name]}name="a_bogus_text_asset" />}
      save_asset_at(@dependant, 1994)
      @dependant.dependencies.effectively_updated_at.should == Time.gm(1994)
    end


    it "should reflect a dependency's creation date/time when that dependency (which previously didn't exist) is created" do
      @dependant.content = %{<r:#{current_tag[:name]} name="dependency" />}
      save_asset_at(@dependant, 1994)

      @dependency = current_tag[:class].new(:name => 'dependency')
      save_asset_at(@dependency, 1995)

      @dependant = current_tag[:class].find_by_name('dependant')
      @dependant.dependencies.effectively_updated_at.should == Time.gm(1995)
    end


    it "should reflect its own change date/time when it is updated" do
      @dependant.content = %{<r:#{current_tag[:name]} name="dependency" />}
      save_asset_at(@dependant, 1991)

      @dependency = current_tag[:class].new(:name => 'dependency')
      save_asset_at(@dependency, 1995)

      save_asset_at(@dependant, 1999)

      @dependant = current_tag[:class].find_by_name('dependant')
      @dependant.dependencies.effectively_updated_at.should == Time.gm(1999)
    end


    it "should reflect a dependency's change date/time once that dependency is updated" do
      @dependency = current_tag[:class].new(:name => 'dependency')
      save_asset_at(@dependency, 1990)

      @dependant.content = %{<r:#{current_tag[:name]} name="dependency" />}
      save_asset_at(@dependant, 1992)

      save_asset_at(@dependency, 1993)

      @dependant = current_tag[:class].find_by_name('dependant')
      @dependant.dependencies.effectively_updated_at.should == Time.gm(1993)
    end


    it "should reflect a dependency's deletion date/time when that dependency file is removed" do
      @dependency = current_tag[:class].new(:name => 'dependency')
      save_asset_at(@dependency, 1996)

      @dependant.content = %{<r:#{current_tag[:name]} name="dependency" />}
      save_asset_at(@dependant, 1997)

      Time.stub!(:now).and_return(Time.gm(1998))
      @dependency.destroy

      @dependant = current_tag[:class].find_by_name('dependant')
      @dependant.dependencies.effectively_updated_at.should == Time.gm(1998)
    end

  end

end


private

  def save_asset_at(text_asset, year)
    Time.stub!(:now).and_return(Time.gm(year))
    text_asset.save!
  end