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
  
  it "asks for a password by posting back status=password" do
    # then
    @messenger.should_receive(:post).
      with(:status => 'password', :data => {:as => 'root', :user => ENV['USER']})
    
    # when
    @messenger.stub!(:get).and_return(:status => 'ok', :data => 'password')
    @officer.ask_for_password('root')
  end
  
  it "returns the password given upstream" do
    # when
    @messenger.stub!(:post)
    @messenger.stub!(:get).and_return(:status => 'ok', :data => 'password')
    
    # then
    @officer.ask_for_password('root').must == 'password'
  end
end
