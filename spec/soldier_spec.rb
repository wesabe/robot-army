require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::Soldier do
  before do
    # given
    @messenger = mock(:messenger)
    @soldier = RobotArmy::Soldier.new(@messenger)
  end
  
  it "can accept eval commands" do
    # then
    @soldier.run(:eval, :code => '3+4', :file => __FILE__, :line => __LINE__).
      must == 7
    
    # and
    @soldier.run(:eval, :code => 'Time.now', :file => __FILE__, :line => __LINE__).
      must be_an_instance_of(Time)
  end
  
  it "evaluates each command in the same process" do
    # when
    pid = proc{ @soldier.run(:eval, :code => 'Process.pid', :file => __FILE__, :line => __LINE__) }
    
    # then
    pid.call.must == pid.call
  end
  
  it "raises on unrecognized commands" do
    proc{ @soldier.run(:foo, nil) }.must raise_error(ArgumentError)
  end
  
  it "listens for commands from the messenger to run" do
    # then
    @soldier.should_receive(:run).with(:eval, :code => 'Hash.new')
    
    # when
    @messenger.stub!(:post)
    @messenger.stub!(:get).and_return(:command => :eval, :data => {:code => 'Hash.new'})
    @soldier.listen
  end
  
  it "posts through the messenger the result of commands run by listening" do
    # then
    @messenger.should_receive(:post).with(:status => 'ok', :data => 1)
    
    # when
    @messenger.stub!(:get).and_return(:command => :eval, :data => {:code => '1'})
    @soldier.stub!(:run).and_return(1)
    @soldier.listen
  end
  
  it "posts back and raises RobotArmy::Exit when running the exit command" do
    @messenger.should_receive(:post).with(:status => 'ok')
    proc{ @soldier.run(:exit, nil) }.must raise_error(RobotArmy::Exit)
  end
  
  it "returns the pid and type when asked for info" do
    @soldier.run(:info, nil).must == {:pid => Process.pid, :type => 'RobotArmy::Soldier'}
  end
  
  it "posts back a warning if the :eval return value is not marshalable" do
    # then
    @messenger.should_receive(:post).
      with(:status => 'warning', :data => "ignoring invalid remote return value #{$stdin.inspect}")
    
    # when
    @messenger.stub!(:get).and_return(
      :command => :eval, :data => {:code => '$stdin', :file => __FILE__, :line => __LINE__})
    @soldier.listen
  end
end
