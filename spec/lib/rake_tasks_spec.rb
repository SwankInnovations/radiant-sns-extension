# I would still like to implement these some day but I had too many problems
# with Radiant environments and Rake


#require File.dirname(__FILE__) + '/../spec_helper'
#require "rake"
#
#describe_rake_task 'config test=ABC', 'lib/tasks/sns_extension_tasks.rake' do
#  describe "with no parameters" do
#    it "should output the current configuration" do
##      ARGV = ["config"].freeze
#      invoke!
#      puts ARGV.inspect
#    end
#  end
#end
#
#
##describe "radiant:extensions:sns:config rake task" do
##
##  before(:each) do
##    puts
##    puts RADIANT_ROOT
##    puts
##    @rake = Rake::Application.new
##    Rake.application = @rake
##    load 'lib/tasks/sns_extension_tasks.rake'
##    load RADIANT_ROOT + '/vendor/rails/railties/lib/tasks/misc.rake'
###    require 'rake_tasks_spec.rb'
##  end
##
##
##  after(:each) do
##    Rake.application = nil
##  end
##
##
##  describe "with no parameters" do
##
##    it "should output the current configuration" do
##      @rake['radiant:extensions:sns:config'].invoke
##      puts ENV.inspect
##    end
##
##  end
##end
#
#
