require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::Loader do
  before do
    @loader = RobotArmy::Loader.new
    @loader.stub!(:exit)
    @messenger = @loader.messenger = mock(:messenger)
    @messenger.stub!(:post)
  end
  
  it "responds with status='ok' after catching the RobotArmy::Exit exception" do
    # then
    @messenger.should_receive(:post).with(:status => 'ok')
    
    # when
    @loader.safely{ raise RobotArmy::Exit }
  end
  
  it "exits after catching the RobotArmy::Exit exception" do
    # then
    @loader.should_receive(:exit)
    
    # when
    @loader.safely{ raise RobotArmy::Exit }
  end
end
