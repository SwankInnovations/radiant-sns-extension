require File.dirname(__FILE__) + '/../spec_helper'

describe CssAsset do
  scenario :stylesheets

  it "should compress stylesheets when 'minify' is set to TRUE" do
    create_css_asset('radiant.css',
                    :minify => true,
                    :raw_content => sample('radiant.css'))
    css_assets('radiant_css').content.should == sample('radiant.minified.css')
  end

  it "should not compress stylesheets when 'minify' is set to FALSE" do
    create_css_asset('radiant.css',
                    :minify => false,
                    :raw_content => sample('radiant.css'))
    css_assets('radiant_css').content.should == sample('radiant.css')
  end

  it "should properly remove trailing semicolons, combine 4 common dimensions into one and 2 sets of 2 dimensions into 2 (see samples for more info)" do
    create_css_asset('test.css',
                    :minify => true,
                    :raw_content => sample('test.css'))
    puts "calculated minified: " + css_assets('test_css').content.length.to_s
    css_assets('test_css').content.should == sample('test.minified.css')
  end

  
  private
    def sample(filename)
      open(File.dirname(__FILE__) + '/../samples/' + filename) { |f| f.read }
    end

end