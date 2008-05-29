class RobotArmy::Officer < RobotArmy::Soldier
  def run(command, data)
    case command
    when :eval
      debug "officer delegating eval command for user=#{data[:user].inspect}"
      RobotArmy::Connection.localhost(data[:user], data[:password]) do |local|
        local.post(:command => command, :data => data)
        return RobotArmy::Connection.handle_response(local.get)
      end
    when :exit
      super
    else
      super
    end
  end
end
