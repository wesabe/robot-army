module RobotArmy
  class Loader
    attr_accessor :messenger
    
    def libraries
      @libraries ||= []
    end
    
    def render
      %{
        #{libraries.map{|l| "require #{l.inspect}"}.join("\n")}
        loader = #{self.class.name}.new
        
        $stdout.sync = $stdin.sync = true
        loader.messenger = RobotArmy::Messenger.new($stdin, $stdout)
        loader.load
      }
    end
    
    def safely
      begin
        return yield, true
      rescue Object => e
        messenger.post(:status => 'error', :data => e)
        return nil, false
      end
    end
    
    def safely_or_die(&block)
      retval, success = safely(&block)
      exit(1) unless success
      return retval
    end
    
    def load
      # create a soldier
      soldier = safely_or_die{ RobotArmy::Soldier.new(messenger) }
      
      # use the soldier to start listening to incoming commands
      # at this point everything has been loaded successfully, so we
      # don't have to exit if an exception is thrown
      loop do
        safely{ soldier.listen }
      end
    end
  end
end
