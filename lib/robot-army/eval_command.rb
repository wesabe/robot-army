class RobotArmy::EvalCommand
  def initialize
    if block_given?
      yield self
    end
  end

  attr_accessor :proc

  attr_accessor :args

  attr_accessor :context

  attr_accessor :dependencies
end
