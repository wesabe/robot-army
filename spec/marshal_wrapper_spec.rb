require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::MarshalWrapper do
  before do
    @string = "foo"
    @string_wrapper = RobotArmy::MarshalWrapper.new(Marshal.dump(@string))
    
    # there is no Foo class, so this shouldn't be loadable
    @invalid_wrapper = RobotArmy::MarshalWrapper.new("o:Foo")
  end
  
  it "acts like the wrapped object if it can be loaded" do
    @string_wrapper.to_s.must == @string
  end
  
  it "raises an exception if the dump can't be loaded" do
    proc{ @invalid_wrapper.to_s }.must raise_error(ArgumentError)
  end
end
