class RobotArmy::Soldier
  attr_reader :messenger
  
  def initialize(messenger)
    @messenger = messenger
  end
  
  def listen
    request  = messenger.get
    result   = run(request[:command], request[:data])
    if result.marshalable?
      response = {:status => 'ok', :data => result}
    else
      response = {
        :status => 'warning', 
        :data => "ignoring invalid remote return value #{result.inspect}"}
    end
    debug "#{self.class} post(#{response.inspect})"
    messenger.post response
  end
  
  def run(command, data)
    debug "#{self.class} running command=#{command.inspect}"
    case command
    when :info
      {:pid => Process.pid, :type => self.class.name}
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
