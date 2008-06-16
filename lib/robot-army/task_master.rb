module RobotArmy
  class TaskMaster < Thor
    def initialize(*args)
      super
      @dep_loader = DependencyLoader.new
    end
    
    # Gets or sets a single host that instances of +TaskMaster+ subclasses will use.
    # 
    # ==== Parameters
    # host<String, nil>::
    #   The fully-qualified domain name to connect to.
    # 
    # ==== Returns
    # String, nil:: The current value for the host.
    # 
    # ==== Alternatives
    # If no argument is provided just returns the current host.
    # 
    # @public
    def self.host(host=nil)
      hosts [host] if host
      hosts && hosts.first
    end
    
    # Gets or sets the hosts that instances of +TaskMaster+ subclasses will use.
    # 
    # ==== Parameters
    # hosts<Array[String]>::
    #   A list of fully-qualified domain names to connect to.
    # 
    # ==== Returns
    # Array[String]:: The current list of hosts.
    # 
    # ==== Alternatives
    # If no argument is provided just returns the current hosts.
    # 
    # @public
    def self.hosts(hosts=nil)
      @hosts = hosts if hosts
      @hosts
    end
    
    # Gets the first host for this instance of +TaskMaster+.
    # 
    # ==== Returns
    # String, nil:: The host value to use.
    # 
    # @public
    def host
      hosts && hosts.first
    end
    
    # Sets a single host for this instance of +TaskMaster+.
    # 
    # ==== Parameters
    # host<String, nil>:: The host value to use.
    # 
    # @public
    def host=(host)
      @hosts = [host]
    end
    
    # Gets the hosts for the instance of +TaskMaster+.
    # 
    # ==== Returns
    # Array[String]:: A list of hosts.
    # 
    # @public
    def hosts
      @hosts || self.class.hosts
    end
    
    # Sets the hosts for this instance of +TaskMaster+.
    # 
    # ==== Parameters
    # hosts<Array[String]>:: A list of hosts.
    # 
    # @public
    def hosts=(hosts)
      @hosts = hosts
    end
    
    # Gets an open connection for the host this instance is configured to use.
    # 
    # ==== Returns
    # RobotArmy::Connection:: An open connection with an active Ruby process.
    # 
    # 
    # @public
    def connection(host)
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
    # ==== Raises
    # Exception:: Whatever is raised by the block.
    # 
    # ==== Returns
    # Object:: Whatever is returned by the block.
    # 
    # @public
    def sudo(hosts=self.hosts, &proc)
      @sudo_password ||= ask_for_password('root')
      remote hosts, :user => 'root', :password => @sudo_password, &proc
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
    # ==== Parameters
    # host<String, nil>::
    #   The fully-qualified domain name of the machine to connect to, or nil if 
    #   you want to use localhost.
    # 
    # ==== Raises
    # Exception:: Whatever is raised by the block.
    # 
    # ==== Returns
    # Object:: Whatever is returned by the block.
    # 
    # @public
    def remote(hosts=self.hosts, options={}, &proc)
      hosts ||= [nil]
      results = hosts.map {|host| remote_eval({:host => host}.merge(options), &proc) }
      results.size == 1 ? results.first : results
    end
    
    # Copies src to dest on each host.
    # 
    # ==== Parameters
    # src<String>:: The path to a local file to copy.
    # dest<String>:: The path of a remote file to copy to.
    # 
    # @public
    def scp(src, dest)
      hosts = self.hosts
      hosts = [nil] if hosts.nil?
      hosts.each{ |host| system "scp #{src} #{"#{host}:" if host}#{dest}" }
    end
    
    # Add a gem dependency this TaskMaster checks for on each remote host.
    # 
    # ==== Parameters
    # dep<String>:: The name of the gem to check for.
    # ver<String>:: The version string of the gem to check for.
    # 
    # @public
    def dependency(dep, ver = nil)
      @dep_loader.add_dependency dep, ver
    end
    
  private
    
    def say(something)
      puts "** #{something}"
    end
    
    # Handles remotely eval'ing a Ruby Proc.
    # 
    # ==== Options (options)
    # :host<String>:: Which host to connect to.
    # :user<String>::
    #   The name of the remote user to use. If this option is provided, the 
    #   command will be executed with sudo, even if the user is the same as 
    #   the user running the process.
    # :password<String>:: The password to give when running sudo.
    # 
    # ==== Returns
    # Object:: Whatever the block returns.
    # 
    # ==== Raises
    # Exception:: Whatever the block raises.
    # 
    # @private
    def remote_eval(options, &proc)
      host = options[:host]
      
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
      
      # include dependency loader
      dep_loading = "Marshal.load(#{Marshal.dump(@dep_loader).inspect}).load!"
      
      code = %{
        #{dep_loading} # load dependencies
        #{locals.join("\n")}  # all local variables
        #{proc.to_ruby(true)} # the proc itself
      }
      
      options[:file] = file
      options[:line] = line
      options[:code] = code
      
      ##
      ## send the child a message
      ##
      
      connection(host).messenger.post(:command => :eval, :data => options)
      
      ##
      ## get and evaluate the response
      ##
      
      response = connection(host).messenger.get
      connection(host).handle_response(response)
    end
    
    def ask_for_password(user)
      require 'highline'
      HighLine.new.ask("[sudo] password: ") {|q| q.echo = false}
    end
  end
end
