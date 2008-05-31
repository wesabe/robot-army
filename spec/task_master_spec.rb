require File.dirname(__FILE__) + '/spec_helper'

class Example < RobotArmy::TaskMaster
end

class Localhost < RobotArmy::TaskMaster
  host nil
end

describe RobotArmy::TaskMaster do
  before do
    @master = Localhost.new
  end
  
  it "allows setting host on the class" do
    Example.host 'example.com'
    Example.host.must == 'example.com'
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
  
  it "prints the child Ruby's stderr to stderr" do
    pending
    stderr_from { @master.remote { $stderr.print "foo" } }.must == "foo"
  end
  
  it "runs multiple remote blocks for the same host in different processes" do
    @master.remote { $a = 1 }
    @master.remote { $a }.must be_nil
  end
  
  it "only loads one Officer process on the remote machine" do
    info = @master.connection.info
    info[:pid].must_not == Process.pid
    info[:type].must == 'RobotArmy::Officer'
    @master.connection.info.must == info
  end
  
  it "runs as a normal (non-super) user by default" do
    @master.remote{ Process.uid }.must_not == 0
  end
  
  it "allows running as super-user" do
    pending('figure out a way to run this only sometimes')
    @master.sudo{ Process.uid }.must == 0
  end
  
  it "loads dependencies" do
    @master.dependency "thor"
    @master.remote { Thor ; 45 }.must == 45 # loading should not bail here
  end
end
