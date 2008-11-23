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
      @text_asset.dependency.names.should == ["main"]
    end


    it 'should log a dependency even if the reference file does not exist' do
      @text_asset.content = %{<r:#{current_tag[:name]} name="a_nonexistent_file" />}
      @text_asset.save!
      @text_asset.dependency.names.should == ["a_nonexistent_file"]
    end


    it 'should log only one dependency if mulitiple tags all reference the the same file' do
      @text_asset.content << %{<r:#{current_tag[:name]} name="main" />}
      @text_asset.save!
      @text_asset.dependency.names.should == ["main"]
    end


    it 'should log multiple dependencies if multiple files are referenced' do
      @text_asset.content << %{<r:#{current_tag[:name]} name="another_file" />}
      @text_asset.save!
      @text_asset.dependency.names.sort.should == ["another_file", "main"]
    end


    it 'should log only each dependency only once' do
      @text_asset.content << %{<r:#{current_tag[:name]} name="another_file" />}
      @text_asset.content << %{<r:#{current_tag[:name]} name="main" />}
      @text_asset.save!
      @text_asset.dependency.names.sort.should == ["another_file", "main"]
    end

  end




  describe "A saved #{current_tag[:name]}'s effectively_updated_at method" do
    before :each do
      @dependant = current_tag[:class].new(:name => 'dependant')
      save_asset_at(@dependant, 1980)
    end


    it "should reflect its own creation date/time (created_at) if the file hasn't been updated and has no dependencies" do
      @dependant.effectively_updated_at.should == Time.utc(1980)
    end


    it "should reflect its own change date/time (updated_at) if the file has no dependencies" do
      save_asset_at(@dependant, 1981)
      @dependant.effectively_updated_at.should == Time.utc(1981)
    end


    it "should reflect its own change date/time if it references dependencies which do not exist" do
      @dependant.content = %{<r:#{current_tag[:name]}name="a_bogus_text_asset" />}
      save_asset_at(@dependant, 1982)
      @dependant.effectively_updated_at.should == Time.utc(1982)
    end


    it "should reflect a dependency's creation date/time when that dependency (which previously didn't exist) is created" do
      @dependant.content = %{<r:#{current_tag[:name]} name="dependency" />}
      save_asset_at(@dependant, 1983)

      @dependency = current_tag[:class].new(:name => 'dependency')
      save_asset_at(@dependency, 1984)

      @dependant = current_tag[:class].find_by_name('dependant')
      @dependant.effectively_updated_at.should == Time.utc(1984)
    end


    it "should reflect its own change date/time when it is updated" do
      @dependant.content = %{<r:#{current_tag[:name]} name="dependency" />}
      save_asset_at(@dependant, 1985)

      @dependency = current_tag[:class].new(:name => 'dependency')
      save_asset_at(@dependency, 1986)

      save_asset_at(@dependant, 1987)

      @dependant = current_tag[:class].find_by_name('dependant')
      @dependant.effectively_updated_at.should == Time.utc(1987)
    end


    it "should reflect a dependency's change date/time once that dependency is updated" do
      @dependency = current_tag[:class].new(:name => 'dependency')
      save_asset_at(@dependency, 1988)

      @dependant.content = %{<r:#{current_tag[:name]} name="dependency" />}
      save_asset_at(@dependant, 1989)

      save_asset_at(@dependency, 1990)

      @dependant = current_tag[:class].find_by_name('dependant')
      @dependant.effectively_updated_at.should == Time.utc(1990)
    end


    it "should reflect a dependency's deletion date/time when that dependency file is removed" do
      @dependency = current_tag[:class].new(:name => 'dependency')
      save_asset_at(@dependency, 1991)

      @dependant.content = %{<r:#{current_tag[:name]} name="dependency" />}
      save_asset_at(@dependant, 1992)

      Time.stub!(:now).and_return(Time.utc(1993))
      @dependency.destroy

      @dependant = current_tag[:class].find_by_name('dependant')
      @dependant.effectively_updated_at.should == Time.utc(1993)
    end

  end



# These specs deal with TextAsset objects automatically recreating the associated
# dependency objects (and their values) upon initialization.  I'm not sure this
# is really a requirement but I'll keep the specs here (commented out) since I
# did the work of creating them in case I change my mind later.
#  describe "an existing #{current_tag[:name]}" do
#    require 'scenarios'
#
#    before :each do
#      create_record :text_asset, :dependant,
#          :name => 'data-missing',
#          :class_name => current_tag[:class].to_s,
#          :content => "<r:#{current_tag[:name]} name='dependency1'/>" +
#                      "<r:#{current_tag[:name]} name='dependency2'/>",
#          :updated_at => Time.utc(1990)
#      create_record :text_asset, :dependency1,
#          :name => 'dependency1',
#          :class_name => current_tag[:class].to_s,
#          :updated_at => Time.utc(1980)
#      create_record :text_asset, :dependency2,
#          :name => 'dependency2',
#          :class_name => current_tag[:class].to_s,
#          :updated_at => Time.utc(2000)
#    end
#
#
#
#
#    describe "with no associated TextAssetDependency object" do
#
#      it 'should create a new one during instantiation' do
#        text_assets(:dependant).dependency.id.should ==
#            TextAssetDependency.find_by_text_asset_id(text_assets(:dependant).id)
#      end
#
#    end
#
#
#
#
#    describe 'where the dependency.names is not set (nil)' do
#
#      before :each do
#        # gets the asset (but this will set dependency.names
#        text_asset = text_assets(:dependant)
#        @text_asset_id = @text_asset.id
#        # delete the value for dependency.names and save to db
#        text_asset.dependency.update_attribute('names', nil)
#      end
#
#
#      it 'should reparse dependency names during initialization' do
#        text_assets(:dependant).dependency.names.should ==
#            ['dependency1', 'dependency2']
#      end
#
#
#      it 'should store the reparsed dependency names in the db' do
#        text_assets(:dependant)
#        TextAssetDependency.find_by_text_asset_id(@text_asset_id).names.should ==
#              ['dependency1', 'dependency2']
#      end
#
#    end
#
#
#
#
#    describe 'where the dependency.effectively_updated_at is not set (nil)' do
#
#      before :each do
#        # gets the asset (but this will set dependency.names
#        text_asset = text_assets(:dependant)
#        @text_asset_id = @text_asset.id
#        # delete the value for dependency.names and save to db
#        text_asset.dependency.update_attribute('names', nil)
#      end
#
#
#      it 'should reparse dependency names during initialization' do
#        text_assets(:dependant).dependency.effectively_updated_at.should ==
#            Time.utc(2000)
#      end
#
#
#      it 'should store the reparsed dependency names in the db' do
#        text_assets(:dependant)
#        TextAssetDependency.find_by_text_asset_id(@text_asset_id).effectively_updated_at.should ==
#            Time.utc(2000)
#      end
#
#    end
#
#  end

end