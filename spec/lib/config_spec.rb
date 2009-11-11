# This specifies the behavior for the configuration module that allows extension
# users to modify the default settings used by this extension.

require File.dirname(__FILE__) + '/../spec_helper'

describe Sns::Config do

  it 'should not accept declarations for invalid setting names' do
    lambda{Sns::Config['bogus name'] = "whatever"}.
        should raise_error(RuntimeError, 'Invalid setting name: "bogus name"')
  end


  it 'should return known settings without having to query the database again' do
    # How to test this??
  end




  [ :stylesheet_directory,
    :javascript_directory,
    :stylesheet_mime_type,
    :javascript_mime_type
  ].each do |setting_name|
    describe setting_name do

      it "should accept declarations where the key name is a symbol" do
        Sns::Config[setting_name] = 'a-test-value'
        Sns::Config[setting_name].should eql('a-test-value')
      end


      it "should accept declarations where the key name is a string" do
        Sns::Config[setting_name.to_s] = 'a-test-value'
        Sns::Config[setting_name.to_s].should eql('a-test-value')
      end

    end
  end




  { :stylesheet_directory => 'css',
    :javascript_directory => 'js',
    :stylesheet_mime_type => 'text/css',
    :javascript_mime_type => 'text/javascript'
  }.each do |setting_name, default_value|

    describe setting_name do

      it "should set default value when starting with an empty db" do
        # need to figure out a way to remove our settings from the Config table
        # we can then call Sns::Config.restore_defaults to clear our
        # cache of values
      end


      it "should return default value after calling the #restore_defaults method" do
        Sns::Config[setting_name] = 'a-test-value'
        Sns::Config.restore_defaults
        Sns::Config[setting_name].should eql(default_value)
      end

    end

  end




  # the following specs apply both to css and js directories...
  [:stylesheet_directory, :javascript_directory].each do |setting_name|

    describe setting_name do

      # declare an array of values with alphanumeric-characters, iterate through each and test
      ['abc', 'ABC', 'aBc', 'AbC123'].each do |alpha_num_value|
        it "should allow alphanumeric chars (i.e. #{alpha_num_value.inspect})" do
          Sns::Config[setting_name] = alpha_num_value
          Sns::Config[setting_name].should eql(alpha_num_value)
        end
      end


      # declare an array of values with slashes, iterate through each and test
      ['aBc-123', 'AbC_123', 'a-B_c-1_23'].each do |hyphen_underscore_value|
        it "should allow hyphens, and/or underscores (i.e. #{hyphen_underscore_value.inspect})" do
          Sns::Config[setting_name] = hyphen_underscore_value
          Sns::Config[setting_name].should eql(hyphen_underscore_value)
        end
      end


      # declare an array of values with slashes, iterate through each and test
      ['aBc/123', 'Ab-C/1_23', 'a/B_c-1/2_3'].each do |slash_value|
        it "should allow slashes (i.e. #{slash_value.inspect})" do
          Sns::Config[setting_name] = slash_value
          Sns::Config[setting_name].should eql(slash_value)
        end
      end


      it 'should change an acceptable value ending in a "/" to one without' do
        Sns::Config[setting_name] = "abc/123/"
        Sns::Config[setting_name].should eql("abc/123")
      end


      it 'should change an acceptable value starting with a "/" to one without' do
        Sns::Config[setting_name] = "/abc/123"
        Sns::Config[setting_name].should eql("abc/123")
      end


      # declare an array of invalid characters, inject them into valid values and test
      %w[! @ # $ % ^ & * ( ) { } < > + = ? , : ; ' " \\ \t \  \n \r \[ \]].each do |invalid_char|
        it "should reject invalid characters (i.e. #{invalid_char.inspect})" do
          lambda{Sns::Config[setting_name] = "aBc#{invalid_char}123"}.should raise_error(
            RuntimeError,
            %{Invalid #{setting_name} value: "#{('aBc' + invalid_char + '123')}"}
          )
        end
      end


      # declare an array of values with bad/multiple slashes, iterate through each and test
      ['//abc/123', 'abc/123//', '/abc///123/','abc\123'].each do |slash_value|
        it "should reject invalid use of slashes (i.e. #{slash_value.inspect})" do
          lambda{Sns::Config[setting_name] = slash_value}.should raise_error(
            RuntimeError,
            %{Invalid #{setting_name} value: "#{(slash_value)}"}
          )
        end
      end

    end

  end




  # the following specs apply both to css and js mime_types...
  [:stylesheet_mime_type, :javascript_mime_type].each do |setting_name|

    describe setting_name do

      ['text/javascript', 'text/javascript1.0', 'text/x-javascript', 'text/css',
       'application/x-ecmascript'].each do |mime_example|
        it "should allow valid mime-types (i.e. #{mime_example.inspect})" do
          Sns::Config[setting_name] = mime_example
          Sns::Config[setting_name].should eql(mime_example)
        end
      end


      # declare an array of invalid characters, inject them into valid values and test
      %w[! @ # $ % ^ & * ( ) { } < > + = ? , : ; ' " _ \\ \t \  \n \r \[ \]].each do |invalid_char|
        it "should reject invalid characters (i.e. #{invalid_char.inspect})" do
          lambda{Sns::Config[setting_name] = "text/x-#{invalid_char}javascript"}.should raise_error(
            RuntimeError,
            %{Invalid #{setting_name} value: "#{('text/x-' + invalid_char + 'javascript')}"}
          )
        end
      end


      it 'should reject mime-types ending in a "/"' do
          lambda{Sns::Config[setting_name] = "text/"}.should raise_error(
            RuntimeError,
            "Invalid #{setting_name} value: #{('text/').inspect}"
          )
      end

    end

  end

end