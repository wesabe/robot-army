require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::AtExit do
  before do
    @at_exit = RobotArmy::AtExit.shared_instance
  end

  it "runs the provided block when directed" do
    foo = 'foo'
    @at_exit.at_exit { foo = 'bar' }
    foo.should == 'foo'
    @at_exit.do_exit
    foo.should == 'bar'
  end

  it "does not run the same block twice" do
    foo = 0
    @at_exit.at_exit { foo += 1 }
    foo.should == 0
    @at_exit.do_exit
    foo.should == 1
    @at_exit.do_exit
    foo.should == 1
  end
end
