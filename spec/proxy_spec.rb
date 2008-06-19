require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::Proxy do
  before do
    # given
    @messenger = stub(:messenger, :post => nil, :get => nil)
    @hash = self.hash
    @proxy = RobotArmy::Proxy.new(@messenger, @hash)
  end
  
  it "posts back a proxy status when a method is called on it" do
    # then
    @messenger.should_receive(:post).
      with(:status => 'proxy', :data => {:hash => @hash, :call => [:to_s]})
    
    # when
    RobotArmy::Connection.stub!(:handle_response)
    @proxy.to_s
  end
  
  it "returns the value returned by a successful incoming message" do
    # when
    @messenger.stub!(:get).and_return(:status => 'ok', :data => 'bar')
    
    # then
    @proxy.to_s.must == 'bar'
  end
  
  it "lets exceptions bubble up from handling the message" do
    # when
    RobotArmy::Connection.stub!(:handle_response).and_raise
    
    # then
    proc { @proxy.to_s }.must raise_error
  end
  
  it "can generate Ruby code to create a Proxy for an object" do
    RobotArmy::Proxy.generator_for(self).
      must == "RobotArmy::Proxy.new(RobotArmy.upstream, #{self.hash.inspect})"
  end
end
