require File.dirname(__FILE__) + '/spec_helper'

describe Proc, "to_ruby" do
  before do
    @proc = proc{ 1 }
  end
  
  it "can render itself as ruby not enclosed in a proc" do
    @proc.to_ruby(true).must == "\n  1"
  end
  
  it "can render itself as ruby that evaluates to a Proc" do
    @proc.to_ruby(false).must == "proc { 1 }"
  end
  
  it "defaults to rendering as ruby without executing itself" do
    @proc.to_ruby.must == @proc.to_ruby(false)
  end
  
  it "can get a list of arguments" do
    proc{ |a, b| a + b }.arguments.must == %w[a b]
  end
end

class MethodToRubyFixture
  def one
    1
  end
  
  def echo(a)
    a
  end
  
  def add(a, b)
    a + b
  end
end

describe Method, "to_ruby" do
  before do
    @method = MethodToRubyFixture.new.method(:one)
  end
  
  it "can render itself as ruby that executes itself" do
    @method.to_ruby(true).must == "\n  1"
  end
  
  it "can render itself as ruby that evaluates to a Method" do
    @method.to_ruby(false).must == "def one\n  1\nend"
  end
  
  it "defaults to rendering as ruby without executing itself" do
    @method.to_ruby.must == @method.to_ruby(false)
  end
end

describe Method, "arguments" do
  before do
    @no_args = MethodToRubyFixture.new.method(:one)
    @one_arg = MethodToRubyFixture.new.method(:echo)
    @many_args = MethodToRubyFixture.new.method(:add)
  end
  
  it "returns an empty list for a method without arguments" do
    @no_args.arguments.must == []
  end
  
  it "returns a single argument for a method with a single argument" do
    @one_arg.arguments.must == %w[a]
  end
  
  it "returns a comma-separated list of arguments when there are many args" do
    @many_args.arguments.must == %w[a b]
  end
end