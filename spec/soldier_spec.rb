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
end
