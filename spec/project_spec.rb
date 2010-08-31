require "#{File.dirname(__FILE__)}/spec_helper"

#describe 'User' do
#  before(:each) do
#    @user = Factory.build(:user)
#  end
#
#  it 'should be created' do
#    @user.should_not be_nil
#  end
#end
#

describe 'New Project' do
  it 'should be able to clone, pull, do last commit and run cuke features' do
    project = Project.clone("capybara-demo","git://github.com/mikeymckay/sinatra-cucumber-capybara-envjs.git")
    project.save
    Project.first(:readable_guid => project.readable_guid).should == project
    Dir.entries(project.data_dir).length.should > 2
    project.pull
    project.last_commit
    project.last_commit_author.should == "Mike McKay"
    project.process_features
    project.scenarios.should_not == nil
    project.steps.should_not == nil
  end

end
