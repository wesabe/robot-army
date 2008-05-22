class RobotArmy::Officer < RobotArmy::Soldier
  def run(command, data)
    case command
    when :eval
      RobotArmy::Connection.localhost do |local|
        local.post(:command => command, :data => data)
        response = local.get
        case response[:status]
        when 'ok'
          return response[:data]
        when 'error'
          raise response[:data]
        end
      end
    when :exit
      super
    else
      super
    end
  end
end
