class RobotArmy::RemoteEvaler
  attr_reader :connection, :command, :options, :proxies

  def initialize(connection, command)
    @connection = connection
    @command = command
  end

  def execute_command
    @options, @proxies = RobotArmy::EvalBuilder.build(command)
    send_eval_command
    return loop_until_done
  end

  private

  def send_eval_command
    debug("Evaling code remotely:\n#{options[:code]}")
    connection.post(:command => :eval, :data => options)
  end

  def loop_until_done
    catch :done do
      loop { process_response(connection.messenger.get) }
    end
  end

  def process_response(response)
    case response[:status]
    when 'proxy'
      handle_proxy_response(response)
    when 'password'
      connection.post :status => 'ok', :data => RobotArmy.ask_for_password(connection.host, response[:data])
    else
      begin
        throw :done, connection.handle_response(response)
      rescue RobotArmy::Warning => e
        $stderr.puts "WARNING: #{e.message}"
        throw :done, nil
      end
    end
  end

  def handle_proxy_response(response)
    begin
      proxy = proxies[response[:data][:hash]]
      data = proxy.send(*response[:data][:call])
      if data.marshalable?
        connection.post :status => 'ok', :data => data
      else
        proxies[data.hash] = data
        connection.post :status => 'proxy', :data => data.hash
      end
    rescue Object => e
      connection.post :status => 'error', :data => e
    end
  end
end
