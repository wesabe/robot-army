class RobotArmy::AtExit
  def at_exit(&block)
    callbacks << block
  end

  def do_exit
    callbacks.pop.call while callbacks.last
  end

  def self.shared_instance
    @shared_instance ||= new
  end

  private

  def callbacks
    @callbacks ||= []
  end
end
