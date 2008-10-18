require File.dirname(__FILE__) + '/../spec_helper'

describe JsAsset do
  scenario :javascripts

  it "should compress javascripts when 'minify' is set to TRUE" do
    create_js_asset('prototype.js',
                    :minify => true,
                    :raw_content => sample('prototype.js'))
    js_assets('prototype_js').content.should == sample('prototype.minified.js')
  end

  it "should not compress javascripts when 'minify' is set to FALSE" do
    create_js_asset('prototype.js',
                    :minify => false,
                    :raw_content => sample('prototype.js'))
    js_assets('prototype_js').content.should == sample('prototype.js')
  end

  private
    def sample(filename)
      open(File.dirname(__FILE__) + '/../samples/' + filename) { |f| f.read }
    end

end
