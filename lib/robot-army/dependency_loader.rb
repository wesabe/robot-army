module RobotArmy
  class DependencyLoader
    attr_reader :dependencies
    
    def initialize
      @dependencies = []
    end
    
    def add_dependency(name, version_str=nil)
      dep = [name]
      dep << version_str if version_str
      @dependencies << dep
    end
  end
end
