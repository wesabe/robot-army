require File.dirname(__FILE__) + '/spec_helper'

describe Marshal do
  it "can dump Fixnums" do
    42.must be_marshalable
  end
  
  it "can dump Strings" do
    "foo".must be_marshalable
  end
  
  it "can dump Arrays" do
    [2, 'foo'].must be_marshalable
  end
  
  it "can't dump IOs" do
    $stdin.must_not be_marshalable
  end
  
  it "can't dump Methods" do
    method(:to_s).must_not be_marshalable
  end
  
  it "can't dump bindings" do
    binding.must_not be_marshalable
  end
  
  it "can't dump Procs" do
    proc{ 2 }.must_not be_marshalable
  end
  
  it "can't dump anything whose _dump method raises a TypeError" do
    class NotDumpable; def _dump(*args); raise TypeError; end; end
    NotDumpable.new.must_not be_marshalable
  end
end

