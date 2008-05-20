class RobotArmy::Officer < RobotArmy::Soldier
  def run(command, data)
    case command
    when :eval
      RobotArmy::Connection.localhost do |local|
        local.post(:command => command, :data => data)
      end
    when :exit
      super
    else
      super
    end
  end
end
