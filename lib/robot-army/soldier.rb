class RobotArmy::Soldier
  attr_reader :messenger
  
  def initialize(messenger)
    @messenger = messenger
  end
  
  def listen
    request  = messenger.get
    result   = run(request[:command], request[:data])
    response = {:status => 'ok', :data => result}
    messenger.post response
  end
  
  def run(command, data)
    case command
    when :eval
      instance_eval(data[:code], data[:file], data[:line])
    when :exit
      # tell the parent we're okay before we exit
      messenger.post(:status => 'ok')
      raise RobotArmy::Exit
    else
      raise ArgumentError, "Unrecognized command #{command.inspect}"
    end
  end
end
