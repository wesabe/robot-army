class RobotArmy::Proxy
  alias_method :__proxy_instance_eval, :instance_eval
  instance_methods.each { |m| undef_method m unless m =~ /^__/ }
  
  def initialize(messenger, hash)
    @messenger = messenger
    @hash = hash
  end
  
  def self.generator_for(object)
    "RobotArmy::Proxy.new(RobotArmy.upstream, #{object.hash.inspect})"
  end
  
private
  
  def method_missing(*args, &block)
    @messenger.post(:status => 'proxy', :data => {:hash => @hash, :call => args})
    RobotArmy::Connection.handle_response @messenger.get
  end
end
