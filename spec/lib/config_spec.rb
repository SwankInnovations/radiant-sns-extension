require File.dirname(__FILE__) + '/../spec_helper'

describe StylesNScripts::Config do
  
  it 'should not accept declarations for invalid setting names' do
    lambda{StylesNScripts::Config['bogus setting name'] = "whatever"}.should
      raise_error(RuntimeError,
      'text asset response cache location is not settable'
    )
  end


  it 'should return known settings without having to query the database again' do
  end


  [ :stylesheet_directory, 
    :javascript_directory, 
    :stylesheet_mime_type,
    :javascript_mime_type,
    :response_cache_directory
  ].each do |setting_name|
    describe setting_name do

      it "should accept declarations where the key name is a symbol" do
        StylesNScripts::Config[setting_name] = 'a-test-value'
        StylesNScripts::Config[setting_name].should eql('a-test-value')
      end


      it "should accept declarations where the key name is a string" do
        StylesNScripts::Config[setting_name.to_s] = 'a-test-value'
        StylesNScripts::Config[setting_name.to_s].should eql('a-test-value')
      end

    end
  end

  
  { :stylesheet_directory => 'css',
    :javascript_directory => 'js',
    :stylesheet_mime_type => 'text/css',
    :javascript_mime_type => 'text/javascript',
    :response_cache_directory => 'text_asset_cache'
  }.each do |setting_name, default_value|
    describe setting_name do

      it "should set default value when starting with an empty db" do
        # need to figure out a way to remove our settings from the Config table
        # we can then call StylesNScripts::Config.restore_defaults to clear our
        # cache of values
      end


      it "should return default value after calling the #restore_defaults method" do
        StylesNScripts::Config[setting_name] = 'a-test-value'
        StylesNScripts::Config.restore_defaults
        StylesNScripts::Config[setting_name].should eql(default_value)
      end

    end
  end
  
  
  # the following specs apply both to css and js directories...
  [:stylesheet_directory, :javascript_directory].each do |setting_name|
    describe setting_name do


      # declare an array of values with alphanumeric-characters, iterate through each and test
      ['abc', 'ABC', 'aBc', 'AbC123'].each do |alpha_num_value|
        it "should allow alphanumeric chars (like: #{alpha_num_value.inspect})" do
          StylesNScripts::Config[setting_name] = alpha_num_value
          StylesNScripts::Config[setting_name].should eql(alpha_num_value)
        end
      end


      # declare an array of values with slashes, iterate through each and test
      ['aBc-123', 'AbC_123', 'a-B_c-1_23'].each do |hyphen_underscore_value|
        it "should allow hyphens, and/or underscores (like: #{hyphen_underscore_value.inspect})" do
          StylesNScripts::Config[setting_name] = hyphen_underscore_value
          StylesNScripts::Config[setting_name].should eql(hyphen_underscore_value)
        end
      end


      # declare an array of values with slashes, iterate through each and test
      ['aBc/123', 'Ab-C/1_23', 'a/B_c-1/2_3'].each do |slash_value|
        it "should allow slashes (like: #{slash_value.inspect})" do
          StylesNScripts::Config[setting_name] = slash_value
          StylesNScripts::Config[setting_name].should eql(slash_value)
        end
      end


      it 'should change an acceptable value ending in a "/" to one without' do
        StylesNScripts::Config[setting_name] = "abc/123/"
        StylesNScripts::Config[setting_name].should eql("abc/123")
      end


      it 'should change an acceptable value starting with a "/" to one without' do
        StylesNScripts::Config[setting_name] = "/abc/123"
        StylesNScripts::Config[setting_name].should eql("abc/123")
      end


      # declare an array of invalid characters, inject them into valid values and test
      %w[! @ # $ % ^ & * ( ) { } < > + = ? , : ; ' " \\ \t \  \n \r \[ \]].each do |invalid_char|
        it "should reject invalid characters (like:#{invalid_char.inspect})" do
          lambda{StylesNScripts::Config[setting_name] = "aBc#{invalid_char}123"}.should raise_error(
            RuntimeError,
            "invalid #{setting_name} value: #{('aBc' + invalid_char + '123').inspect}"
          )
        end
      end


      # declare an array of values with bad/multiple slashes, iterate through each and test
      ['//abc/123', 'abc/123//', '/abc///123/','abc\123'].each do |slash_value|
        it "should reject invalid use of slashes (like: #{slash_value.inspect})" do
          lambda{StylesNScripts::Config[setting_name] = slash_value}.should raise_error(
            RuntimeError,
            "invalid #{setting_name} value: #{(slash_value).inspect}"
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
        it "should allow valid mime-types (like: #{mime_example.inspect})" do
          StylesNScripts::Config[setting_name] = mime_example
          StylesNScripts::Config[setting_name].should eql(mime_example)
        end
      end


      # declare an array of invalid characters, inject them into valid values and test
      %w[! @ # $ % ^ & * ( ) { } < > + = ? , : ; ' " _ \\ \t \  \n \r \[ \]].each do |invalid_char|
        it "should reject invalid characters (like: #{invalid_char.inspect})" do
          lambda{StylesNScripts::Config[setting_name] = "text/x-#{invalid_char}javascript"}.should raise_error(
            RuntimeError,
            "invalid #{setting_name} value: #{('text/x-' + invalid_char + 'javascript').inspect}"
          )
        end
      end


      it 'should reject mime-types ending in a "/"' do
          lambda{StylesNScripts::Config[setting_name] = "text/"}.should raise_error(
            RuntimeError,
            "invalid #{setting_name} value: #{('text/').inspect}"
          )
      end

    end
  end
  
  
  describe 'response_cache_directory' do

    # declare an array of values with alphanumeric-characters, iterate through each and test
    ['abc', 'ABC', 'aBc', 'AbC123'].each do |alpha_num_value|
      it "should allow a #{:response_cache_directory} with alphanumeric chars (#{alpha_num_value.inspect})" do
        StylesNScripts::Config[:response_cache_directory] = alpha_num_value
        StylesNScripts::Config[:response_cache_directory].should eql(alpha_num_value)
      end
    end


    # declare an array of values with slashes, iterate through each and test
    ['aBc-123', 'AbC_123', 'a-B_c-1_23'].each do |hyphen_underscore_value|
      it "should allow hyphens, and/or underscores (like: #{hyphen_underscore_value.inspect})" do
        StylesNScripts::Config[:response_cache_directory] = hyphen_underscore_value
        StylesNScripts::Config[:response_cache_directory].should eql(hyphen_underscore_value)
      end
    end


    # declare an array of invalid characters, inject them into valid values and test
    %w[! @ # $ % ^ & * ( ) { } < > + = ? , : ; ' " \\ \t \  \n \r \[ \] /].each do |invalid_char|
      it "should reject invalid characters (like:#{invalid_char.inspect})" do
        lambda{StylesNScripts::Config[:response_cache_directory] = "aBc#{invalid_char}123"}.should raise_error(
          RuntimeError,
          "invalid response_cache_directory value: #{('aBc' + invalid_char + '123').inspect}"
        )
      end
    end

  end
end