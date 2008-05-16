require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::Messenger do
  before do
    # given
    @in, @out = StringIO.new, StringIO.new
    
    @messenger = RobotArmy::Messenger.new(@in, @out)
    @response  = {:status => 'ok', :data => 1}
    @dump      = "#{Base64.encode64(Marshal.dump(@response))}|"
  end
  
  it "posts messages to @out" do
    # when
    @messenger.post(@response)
    
    # then
    @out.string.must == @dump
  end
  
  it "gets messages from @in" do
    # when
    @in.string = @dump
    
    # then
    @messenger.get.must == @response
  end
end
