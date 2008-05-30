module RobotArmy
  class DependencyError < StandardError; end
  
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
    
    def load!
      errors = []
      
      @dependencies.each do |name, version|
        begin
          if version
            gem name, version
          else
            gem name
          end
        rescue Gem::LoadError => e
          errors << e.message
        end
      end
      
      unless errors.empty?
        raise DependencyError.new(errors.join("\n"))
      end
    end
    
  end
end
