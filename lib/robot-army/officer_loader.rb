class RobotArmy::OfficerLoader < RobotArmy::Loader
  def load
    # create a soldier
    soldier = safely_or_die{ RobotArmy::Officer.new(messenger) }
    
    # use the soldier to start listening to incoming commands
    # at this point everything has been loaded successfully, so we
    # don't have to exit if an exception is thrown
    loop do
      safely{ soldier.listen }
    end
  end
end
