require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::GateKeeper do
  before do
    # given
    @keeper = RobotArmy::GateKeeper.new
    @host = 'example.com'
    @connection = mock(:connection)
    @connection.stub!(:closed?).and_return(false)
  end
  
  it "establishes a new connection to a host if one does not already exist" do
    # then
    @keeper.should_receive(:establish_connection).with(@host)
    
    # when
    @keeper.stub!(:get_connection).and_return(nil)
    @keeper.connect(@host)
  end
  
  it "terminates all connections on close" do
    # then
    @connection.should_receive(:close)
    
    # when
    @keeper.stub!(:connections).and_return(@host => @connection)
    @keeper.close
  end
  
  it "creates a new Connection with the given host when establish_connection is called" do
    # then
    RobotArmy::OfficerConnection.should_receive(:new).with(@host).and_return(@connection)
    @connection.should_receive(:open).and_return(@connection)
    
    # when
    @keeper.establish_connection(@host)
    
    # and
    @keeper.connections[@host].should == @connection
  end
  
  it "has a shared instance that doesn't change" do
    RobotArmy::GateKeeper.shared_instance.should be_an_instance_of(RobotArmy::GateKeeper)
    RobotArmy::GateKeeper.shared_instance.should == RobotArmy::GateKeeper.shared_instance
  end
end
