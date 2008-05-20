class RobotArmy::Connection
  attr_reader :host, :messenger
  
  def initialize(host)
    @host = host
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
  
  def start_child
    begin
      ##
      ## bootstrap the child process
      ##
    
      # small hack to retain control of stdin
      cmd = %{ruby -rbase64 -e "eval(Base64.decode64(STDIN.gets(%(|))))"}
      cmd = "ssh #{host} '#{cmd}'" if host
    
      stdin, stdout, stderr = Open3.popen3 cmd
      stdin.sync = stdout.sync = stderr.sync = true
    
      loader.libraries.replace $TESTING ? 
        [File.join(File.dirname(__FILE__), '..', 'robot-army')] : %w[rubygems robot-army]
    
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
  
  def self.localhost(&block)
    conn = new(nil)
    block ? conn.open(&block) : conn
  end
end
