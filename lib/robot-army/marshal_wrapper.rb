# Wraps the result of a +Marshal.dump+ call so that, on the remote side, 
# problems calling +Marshal.load+ on something only occur when you try to 
# access it. This arguably hides bugs, and should probably be revisited.
# 
# @public
class RobotArmy::MarshalWrapper
  instance_methods.each { |m| undef_method m unless m =~ /^__/ }
  
  def initialize(dump)
    @dump = dump
  end
  
private
  
  def load_dump
    @wrapped = Marshal.load(@dump)
  end
  
  def loaded?
    !@wrapped.nil?
  end
  
  def method_missing(method, *args, &block)
    load_dump unless loaded?
    @wrapped.send(method, *args, &block)
  end
end
