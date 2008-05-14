require File.dirname(__FILE__) + '/spec_helper'

class MyRobot < Robot
end

class Localhost < Robot
  host nil
end

describe Robot do
  it "allows setting host on the class" do
    MyRobot.host 'example.com'
    MyRobot.host.must == 'example.com'
  end
end

describe Robot, 'remote' do
  before do
    @robot = Localhost.mock
  end
  
  it "can execute a Ruby block and return the result" do
    @robot.remote { 3+4 }.must == 7
  end
  
  it "executes its block in a different process" do
    @robot.remote { Process.pid }.must_not == Process.pid
  end
  
  it "preserves local variables" do
    a = 42
    @robot.remote { a }.must == 42
  end
  
  it "re-raises exceptions thrown remotely" do
    proc { @robot.remote { raise ArgumentError, "You fool!" } }.
      must raise_error(ArgumentError)
  end
  
  it "prints the child Ruby's stderr to stderr" do
    stderr_from { @robot.remote { $stderr.print "foo" } }.must == "foo"
  end
end
