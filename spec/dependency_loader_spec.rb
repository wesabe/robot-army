require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::DependencyLoader do
  before do
    @loader = RobotArmy::DependencyLoader.new
  end
  
  it "should have no dependencies by default" do
    @loader.dependencies.must == []
  end
  
  it "should store the dependency requirement by name" do
    name = "RedCloth"
    @loader.add_dependency name
    @loader.dependencies.must == [[name]]
  end
  
  it "should store the dependency requirement with version restriction" do
    name = "RedCloth"
    version_str = "> 3.1.0"
    @loader.add_dependency name, version_str
    @loader.dependencies.must == [[name, version_str]]
  end
end
