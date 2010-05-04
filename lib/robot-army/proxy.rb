class RobotArmy::Proxy
  alias_method :__proxy_instance_eval, :instance_eval
  instance_methods.each { |m| undef_method m unless m =~ /^__/ }

  def initialize(messenger, hash)
    @messenger = messenger
    @hash = hash
  end

  def sh(binary, *args)
    command = [binary, *args].join(' ')
    output = %x{#{command} 2>&1}

    if not $?.success?
      raise RobotArmy::ShellCommandError.new(command, $?.exitstatus, output)
    end

    return output
  end

  def self.generator_for(object)
    "RobotArmy::Proxy.new(RobotArmy.upstream, #{object.hash.inspect})"
  end

private

  def method_missing(*args, &block)
    @messenger.post(:status => 'proxy', :data => {:hash => @hash, :call => args})
    response = @messenger.get
    case response[:status]
    when 'proxy'
      return RobotArmy::Proxy.new(@messenger, response[:data])
    else
      return RobotArmy::Connection.handle_response(response)
    end
  end
end
