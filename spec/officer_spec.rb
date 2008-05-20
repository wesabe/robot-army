require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::Officer do
  before do
    # given
    @messenger = mock(:messenger)
    @officer = RobotArmy::Officer.new(@messenger)
  end
  
  it "evaluates each command in a different process" do
    # when
    pid = proc{ @officer.run(:eval, :code => 'Process.pid', :file => __FILE__, :line => __LINE__) }
    
    # then
    pid.call.must_not == pid.call
  end
end
