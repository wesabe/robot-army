require File.dirname(__FILE__) + '/spec_helper'

describe Proc, "to_ruby" do
  before do
    @proc = proc{ 1 }
  end
  
  it "can render itself as ruby that executes itself" do
    @proc.to_ruby(true).must == "proc { 1 }.call"
  end
  
  it "can render itself as ruby that evaluates to a Proc" do
    @proc.to_ruby(false).must == "proc { 1 }"
  end
  
  it "defaults to rendering as ruby without executing itself" do
    @proc.to_ruby.must == @proc.to_ruby(false)
  end
end

class MethodToRubyFixture
  def foo
    1
  end
end

describe Method, "to_ruby" do
  before do
    @method = MethodToRubyFixture.new.method(:foo)
  end
  
  it "can render itself as ruby that executes itself" do
    @method.to_ruby(true).must == "\n  1"
  end
  
  it "can render itself as ruby that evaluates to a Method" do
    @method.to_ruby(false).must == "def foo\n  1\nend"
  end
  
  it "defaults to rendering as ruby without executing itself" do
    @method.to_ruby.must == @method.to_ruby(false)
  end
end