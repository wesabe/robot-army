class RobotArmy::OfficerConnection < RobotArmy::Connection
  def loader
    @loader ||= RobotArmy::OfficerLoader.new
  end
end
