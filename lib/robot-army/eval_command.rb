class RobotArmy::EvalCommand
  def initialize
    yield self if block_given?
  end

  attr_accessor :proc

  attr_accessor :args

  attr_accessor :context

  attr_accessor :dependencies

  attr_accessor :keychain
end
