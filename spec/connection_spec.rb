require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::Connection do
  before do
    # given
    @host = 'example.com'
    @connection = RobotArmy::Connection.new(@host)
    @messenger  = mock(:messenger)
    @connection.stub!(:messenger).and_return(@messenger)
    @connection.stub!(:start_child)
  end
  
  it "is not closed after opening" do
    # when
    @connection.open
    
    # then
    @connection.must_not be_closed
  end
  
  it "returns itself from open" do
    @connection.open.must == @connection
  end
  
  it "does not start another child process if we're already open" do
    # then
    @connection.should_not_receive(:start_child)
    
    # when
    @connection.stub!(:closed?).and_return(false)
    @connection.open
  end
  
  it "raises an exception when calling close if a connection is already closed" do
    # when
    @connection.stub!(:closed?).and_return(true)
    
    # then
    proc{ @connection.close }.must raise_error(RobotArmy::ConnectionNotOpen)
  end
  
  it "sends an exit command to its child upon closing" do
    # then
    @messenger.should_receive(:post).with(:command => :exit)
    
    # when
    @connection.stub!(:closed?).and_return(false)
    @connection.close
  end
end
