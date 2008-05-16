require File.dirname(__FILE__) + '/spec_helper'

class Example < RobotArmy::TaskMaster
end

class Localhost < RobotArmy::TaskMaster
  host nil
end

describe RobotArmy::TaskMaster do
  it "allows setting host on the class" do
    Example.host 'example.com'
    Example.host.must == 'example.com'
  end
end

describe RobotArmy::TaskMaster, 'remote' do
  before do
    @master = Localhost.mock
  end
  
  it "can execute a Ruby block and return the result" do
    @master.remote { 3+4 }.must == 7
  end
  
  it "executes its block in a different process" do
    @master.remote { Process.pid }.must_not == Process.pid
  end
  
  it "preserves local variables" do
    a = 42
    @master.remote { a }.must == 42
  end
  
  it "re-raises exceptions thrown remotely" do
    proc { @master.remote { raise ArgumentError, "You fool!" } }.
      must raise_error(ArgumentError)
  end
  
  # it "prints the child Ruby's stderr to stderr" do
  #   stderr_from { @master.remote { $stderr.print "foo" } }.must == "foo"
  # end
end
