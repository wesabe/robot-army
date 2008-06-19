class RobotArmy::Connection
  attr_reader :host, :user, :password, :messenger
  
  def initialize(host, user=nil, password=nil)
    @host = host
    @user = user
    @password = password
    @closed = true
  end
  
  def loader
    @loader ||= RobotArmy::Loader.new
  end
  
  def open(&block)
    start_child if closed?
    @closed = false
    unless block_given?
      return self
    else
      begin
        return yield(self)
      ensure
        close unless closed?
      end
    end
  end
  
  def password_prompt
    @password_prompt ||= RobotArmy.random_string
  end
  
  def asking_for_password?(stream)
    if RobotArmy.has_data?(stream)
      data = RobotArmy.read_data(stream)
      debug "read #{data.inspect}"
      return data && data =~ /#{password_prompt}\n*$/
    end
  end
  
  def answer_sudo_prompt(stdin, stderr)
    tries = password.is_a?(Proc) ? 3 : 1
    
    tries.times do
      if asking_for_password?(stderr)
        # ask, and you shall receive
        stdin.puts(password.is_a?(Proc) ?
          password.call : password.to_s)
      end
    end
    
    if asking_for_password?(stderr)
      # ack, that didn't work, bail
      stdin.puts
      stderr.readpartial(1024)
      raise RobotArmy::InvalidPassword
    end
  end
  
  def start_child
    begin
      ##
      ## bootstrap the child process
      ##
      
      # small hack to retain control of stdin
      cmd = %{ruby -rbase64 -e "eval(Base64.decode64(STDIN.gets(%(|))))"}
      if user
        # use sudo with custom prompt, reading password from stdin
        cmd = %{sudo -u #{user} -p #{password_prompt} -S #{cmd}}
      end
      cmd = "ssh #{host} '#{cmd}'" unless host == :localhost
      debug "running #{cmd}"
      
      loader.libraries.replace $TESTING ? 
        [File.join(File.dirname(__FILE__), '..', 'robot-army')] : %w[rubygems robot-army]
      
      stdin, stdout, stderr = Open3.popen3 cmd
      stdin.sync = stdout.sync = stderr.sync = true
      
      # look for the prompt
      answer_sudo_prompt(stdin, stderr) if user && password
      
      ruby = loader.render
      code = Base64.encode64(ruby)
      stdin << code << '|'
      
      
      ##
      ## make sure it was loaded okay
      ##
      
      @messenger = RobotArmy::Messenger.new(stdout, stdin)
      response = messenger.get
      
      if response
        case response[:status]
        when 'error'
          $stderr.puts "Error trying to execute: #{ruby.gsub(/^/, '  ')}\n"
          raise response[:data]
        when 'ok'
          # yay! established connection
        end
      else
        # try to get stderr
        begin
          require 'timeout'
          err = timeout(1){ "process stderr: #{stderr.read}" }
        rescue Timeout::Error
          err = 'additionally, failed to get stderr'
        end
      
        raise "Failed to start remote ruby process. #{err}"
      end
    
      ##
      ## finish up
      ##
    
      @closed = false
    rescue Object => e
      $stderr.puts "Failed to establish connection to #{host}: #{e.message}"
      raise e
    ensure
      @closed = true
    end
  end
  
  def info
    post(:command => :info)
    handle_response(get)
  end
  
  def get
    messenger.get
  end
  
  def post(*args)
    messenger.post(*args)
  end
  
  def closed?
    @closed
  end
  
  def close
    raise RobotArmy::ConnectionNotOpen if closed?
    messenger.post(:command => :exit)
    @closed = true
  end
  
  def handle_response(response)
    self.class.handle_response(response)
  end
  
  def self.handle_response(response)
    debug "handling response=#{response.inspect}"
    case response[:status]
    when 'ok'
      return response[:data]
    when 'error'
      raise response[:data]
    when 'warning'
      raise RobotArmy::Warning, response[:data]
    else
      raise RuntimeError, "Unknown response status from remote process: #{response[:status].inspect}"
    end
  end
  
  def self.localhost(user=nil, password=nil, &block)
    conn = new(:localhost, user, password)
    block ? conn.open(&block) : conn
  end
end
