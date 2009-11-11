require File.dirname(__FILE__) + '/../spec_helper'

class SimpleStylesheetFilter < StylesheetFilter
end


class ReverseStylesheetFilter < StylesheetFilter
  filter_name "Custom Filter Name"
  def filter(text)
    text.reverse
  end
end


class SimpleJavascriptFilter < JavascriptFilter
end


class ReverseJavascriptFilter < JavascriptFilter
  filter_name "Custom Filter Name"
  def filter(text)
    text.reverse
  end
end


[ { :class => StylesheetFilter,
    :simple => SimpleStylesheetFilter,
    :reverse => ReverseStylesheetFilter },

  { :class => JavascriptFilter,
    :simple => SimpleJavascriptFilter,
    :reverse => ReverseJavascriptFilter }

].each do |current_filter|

  describe current_filter[:class].to_s.pluralize do

    it "should list all the current subclasssed filters as descendants" do
      # we can't really control all of the filters for our test (the tester may
      # have other filters installed via extension) but we can test that those
      # we've built are found.
      current_filter[:class].descendants.should include(
          current_filter[:simple])
      current_filter[:class].descendants.should include(
          current_filter[:reverse])
    end


    it "should use a subclass's name as the default filter_name (SuperDuperFilter -> 'Super Duper'" do
      current_filter[:simple].filter_name.should == current_filter[:simple].
          to_s.titleize.gsub(/\s*Filter$/, '')
    end


    it "should allow developers to override the default with their own filter_name" do
      current_filter[:reverse].filter_name.should == 'Custom Filter Name'
    end


    it "should pass back the input text unfiltered if a filter is not explicitly defined" do
      current_filter[:simple].filter('my test text').should == 'my test text'
    end


    it "should pass return filtered text via a #filter method" do
      current_filter[:reverse].filter('my test text').should == 'txet tset ym'
    end
  end

end
