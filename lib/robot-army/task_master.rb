module RobotArmy
  class TaskMaster < Thor
    # Gets or sets the host that instances of TaskMaster subclasses will use.
    # 
    # ==== Parameters
    # host<String, nil>::
    #   The fully-qualified domain name to use or to get the current host.
    # 
    # 
    # ==== Returns
    # String, nil:: The current value for the host.
    # 
    # 
    # @public
    def self.host(host=nil)
      @host = host if host
      @host
    end
    
    # Gets the host for this instance of TaskMaster.
    # 
    # ==== Returns
    # String, nil:: The host value to use.
    # 
    # 
    # @public
    def host
      @host || self.class.host
    end
    
    # Sets the host for this instance of TaskMaster.
    # 
    # ==== Parameters
    # String, nil:: The host value to use.
    # 
    # 
    # @public
    def host=(host)
      @host = host
    end
    
    # Gets an open connection for the host this instance is configured to use.
    # 
    # ==== Returns
    # RobotArmy::Connection:: An open connection with an active Ruby process.
    # 
    # 
    # @public
    def connection
      RobotArmy::GateKeeper.shared_instance.connect(host)
    end
    
    # Runs a block of Ruby on the machine specified by a host string as root 
    # and returns the return value of the block. Example:
    # 
    #   sudo { `shutdown -r now` }
    # 
    # See #remote for more information about this.
    # 
    # ==== Parameters
    # host<String, nil>::
    #   The fully-qualified domain name of the machine to connect to, or nil if 
    #   you want to use localhost.
    # 
    # 
    # ==== Raises
    # Exception:: Whatever is raised by the block.
    # 
    # 
    # ==== Returns
    # Object:: Whatever is returned by the block.
    # 
    # 
    # @public
    def sudo(host=self.host, &proc)
      @sudo_password ||= ask_for_password('root')
      remote_eval :host => host, :user => 'root', :password => @sudo_password, &proc
    end
    
    # Runs a block of Ruby on the machine specified by a host string and 
    # returns the return value of the block. Example:
    # 
    #   remote { "foo" } # => "foo"
    # 
    # Local variables accessible from the block are also passed along to the 
    # remote process:
    # 
    #   foo = "bar"
    #   remote { foo } # => "bar"
    # 
    # Objects which can't be marshalled, such as IO streams, print a warning 
    # and are not marshalled:
    # 
    #   stdin = $stdin
    #   remote { defined?(stdin) } # => nil
    # 
    # 
    # ==== Parameters
    # host<String, nil>::
    #   The fully-qualified domain name of the machine to connect to, or nil if 
    #   you want to use localhost.
    # 
    # 
    # ==== Raises
    # Exception:: Whatever is raised by the block.
    # 
    # 
    # ==== Returns
    # Object:: Whatever is returned by the block.
    # 
    # 
    # @public
    def remote(host=self.host, &proc)
      remote_eval :host => host, &proc
    end
    
  private
    
    def say(something)
      puts "** #{something}"
    end
    
    # Handles remotely eval'ing a Ruby Proc.
    # 
    # 
    # ==== Options (options)
    # :user<String>::
    #   The name of the remote user to use. If this option is provided, the 
    #   command will be executed with sudo, even if the user is the same as 
    #   the user running the process.
    # :password<String>:: The password to give when running sudo.
    # 
    # 
    # ==== Returns
    # Object:: Whatever the block returns.
    # 
    # 
    # ==== Raises
    # Exception:: Whatever the block raises.
    # 
    # 
    # @private
    def remote_eval(options, &proc)
      ##
      ## build the code to send it
      ##
      
      # fix stack traces
      file, line = eval('[__FILE__, __LINE__]', proc.binding)
      
      # include local variables
      locals = eval('local_variables', proc.binding).inject([]) do |vars, name|
        begin
          value = eval(name, proc.binding)
          dump  = Marshal.dump(value)
          vars << "#{name} = RobotArmy::MarshalWrapper.new(#{dump.inspect})"
        rescue Object => e
          if e.message =~ /^can't dump/
            $stderr.puts "WARNING: not including local variable '#{name}'"
          else
            raise e
          end
        end
        
        vars
      end
      
      code = %{
        #{locals.join("\n")}  # all local variables
        #{proc.to_ruby(true)} # the proc itself
      }
      
      options[:file] = file
      options[:line] = line
      options[:code] = code
      
      ##
      ## send the child a message
      ##
      
      connection.messenger.post(:command => :eval, :data => options)
      
      ##
      ## get and evaluate the response
      ##
      
      response = connection.messenger.get
      connection.handle_response(response)
    end
    
    def ask_for_password(user)
      require 'highline'
      HighLine.new.ask("[sudo] #{user}@#{host||'localhost'} password: ") {|q| q.echo = false}
    end
  end
end
