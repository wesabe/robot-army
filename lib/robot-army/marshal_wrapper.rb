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
