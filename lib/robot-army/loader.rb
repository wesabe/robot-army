class RobotArmy::Loader
  attr_accessor :messenger
  
  def libraries
    @libraries ||= []
  end
  
  def render
    %{
      begin
        ##
        ## setup
        ##
        
        $stdout.sync = $stdin.sync = true
        #{libraries.map{|l| "require #{l.inspect}"}.join("\n")}
        
        
        ##
        ## local Robot Army objects to communicate with the parent
        ##
        
        loader = RobotArmy::Loader.new
        loader.messenger = RobotArmy::Messenger.new($stdin, $stdout)
        loader.messenger.post(:status => 'ok')
        
        ##
        ## event loop
        ##
        
        loader.load
      rescue Object => e
        ##
        ## exception handler of last resort
        ##
        
        if defined?(RobotArmy::Exit) && e.is_a?(RobotArmy::Exit)
          # don't stomp on our own "let me out" exception
          exit(e.status)
        else
          # if we got here that means something up to and including loader.load
          # went unexpectedly wrong. this could be a missing library, or it 
          # could be a bug in Robot Army. either way we should report the error
          # back to the place we came from so that they may re-raise the exception
          
          # a little bit of un-DRY
          print Base64.encode64(Marshal.dump(:status => 'error', :data => e))+'|'
          exit(1)
        end
      end
    }
  end
  
  def safely
    begin
      return yield, true
    rescue RobotArmy::Exit
      # let RobotArmy::Exit through
      raise
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
