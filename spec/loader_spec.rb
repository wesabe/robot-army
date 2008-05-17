require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::Loader do
  before do
    @loader = RobotArmy::Loader.new
    @messenger = @loader.messenger = mock(:messenger)
    @messenger.stub!(:post)
  end
  
  it "doesn't catch the RobotArmy::Exit exception" do
    proc{ @loader.safely{ raise RobotArmy::Exit } }.must raise_error(RobotArmy::Exit)
  end
end
