require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::DependencyLoader do
  before do
    @loader = RobotArmy::DependencyLoader.new
  end
  
  it "should have no dependencies by default" do
    @loader.dependencies.should == []
  end
  
  it "should store the dependency requirement by name" do
    name = "RedCloth"
    @loader.add_dependency name
    @loader.dependencies.should == [[name]]
  end
  
  it "should store the dependency requirement with version restriction" do
    name = "RedCloth"
    version_str = "> 3.1.0"
    @loader.add_dependency name, version_str
    @loader.dependencies.should == [[name, version_str]]
  end
  
  it "should gem load a dependency by name only" do
    name = "foobarbaz"
    @loader.add_dependency name
    @loader.should_receive(:gem).with(name)
    @loader.load!
  end
  
  it "should gem load a dependency by name and version" do
    name = "foobarbaz"
    version = "> 3.1"
    @loader.add_dependency name, version
    @loader.should_receive(:gem).with(name, version)
    @loader.load!
  end
  
  
  it "should raise when a dependency is not met" do
    @loader.add_dependency "foobarbaz"
    @loader.should_receive(:gem).and_raise Gem::LoadError
    lambda { @loader.load! }.should raise_error(RobotArmy::DependencyError)
  end
end
