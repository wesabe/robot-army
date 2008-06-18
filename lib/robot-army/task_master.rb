module RobotArmy
  # The place where the magic happens
  # 
  # ==== Types (shortcuts for use in this file)
  # HostList:: <Array[String], String, nil>
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
    # ==== Options
    # :user<String>:: The user to run the block as.
    # 
    # ==== Raises
    # Exception:: Whatever is raised by the block.
    # 
    # ==== Returns
    # Object:: Whatever is returned by the block.
    # 
    # @public
    def sudo(hosts=self.hosts, options={}, &proc)
      @sudo_password ||= ask_for_password('root')
      options, hosts = hosts, self.hosts if hosts.is_a?(Hash)
      remote hosts, {:user => 'root', :password => @sudo_password}.merge(options), &proc
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
    # host<HostList>:: Which hosts to run the block on.
    # 
    # ==== Raises
    # Exception:: Whatever is raised by the block.
    # 
    # ==== Returns
    # Array[Object]:: Whatever is returned by the block.
    # 
    # @public
    def remote(hosts=self.hosts, options={}, &proc)
      hosts ||= [nil]
      results = Array(hosts).map {|host| remote_eval({:host => host}.merge(options), &proc) }
      results.size == 1 ? results.first : results
    end
    
    # Copies src to dest on each host.
    # 
    # ==== Parameters
    # src<String>:: A local file to copy.
    # dest<String>:: The path of a remote file to copy to.
    # 
    # @public
    def scp(src, dest, hosts=self.hosts)
      hosts ||= [nil]
      Array(hosts).each{ |host| system "scp #{src} #{"#{host}:" if host}#{dest}" }
      nil
    end
    
    # Copies path to a temporary directory on each host.
    # 
    # ==== Parameters
    # path<String>:: A local file to copy.
    # hosts<HostList>:: Which hosts to connect to.
    # 
    # ==== Returns
    # Array<String>:: An array of destination paths.
    # 
    # ==== Alternatives
    # If only one path is given (or specified in the class) 
    # then a single String will be returned.
    # 
    # @public
    def cptemp(path, hosts=self.hosts)
      hosts ||= [nil]
      tmp_paths = remote{ File.join(%x{mktemp -d -t robot-army}.chomp, File.basename(path)) }
      Array(hosts).zip(Array(tmp_paths)).each do |host, tmp|
        scp path, tmp, host
      end
      tmp_paths.size == 1 ? tmp_paths.first : tmp_paths
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
      something = HighLine.new.color(something, :bold) if defined?(HighLine)
      puts "** #{something}"
    end
    
    # Handles remotely eval'ing a Ruby Proc.
    # 
    # ==== Options (options)
    # :host<HostList>:: Which hosts to connect to.
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
      conn = connection(host)
      proxies = { self.hash => self }
      
      ##
      ## build the code to send it
      ##
      
      # fix stack traces
      file, line = eval('[__FILE__, __LINE__]', proc.binding)
      
      # include local variables
      locals = eval('local_variables', proc.binding).inject([]) do |vars, name|
        value = eval(name, proc.binding)
        if value.marshalable?
          dump  = Marshal.dump(value)
          vars << "#{name} = RobotArmy::MarshalWrapper.new(#{dump.inspect})"
        else
          vars << "#{name} = RobotArmy::Proxy.new(RobotArmy.upstream, #{value.hash.inspect})"
          proxies[value.hash] = value
        end
        
        vars
      end
      
      # include dependency loader
      dep_loading = "Marshal.load(#{Marshal.dump(@dep_loader).inspect}).load!"
      
      # get the code for the proc
      proc = proc.to_ruby
      messenger = "RobotArmy::Messenger.new($stdin, $stdout)"
      context = "RobotArmy::Proxy.new(#{messenger}, #{self.hash.inspect})"
      
      code = %{
        #{dep_loading} # load dependencies
        #{locals.join("\n")}  # all local variables
        context = #{context}  # execution context
        # run the block
        context.__proxy_instance_eval(&#{proc})
      }
      
      options[:file] = file
      options[:line] = line
      options[:code] = code
      
      ##
      ## send the child a message
      ##
      
      conn.post(:command => :eval, :data => options)
      
      ##
      ## get and evaluate the response
      ##
      
      loop do
        # we want to loop until we get something other than "proxy"
        response = conn.messenger.get
        case response[:status]
        when 'proxy'
          begin
            proxy = proxies[response[:data][:hash]]
            data = proxy.send(*response[:data][:call])
            conn.post :status => 'ok', :data => data
          rescue Object => e
            conn.post :status => 'error', :data => e
          end
        else
          begin
            return conn.handle_response(response)
          rescue RobotArmy::Warning => e
            $stderr.puts "WARNING: #{e.message}"
            return nil
          end
        end
      end
    end
    
    def ask_for_password(user)
      require 'highline'
      HighLine.new.ask("[sudo] password: ") {|q| q.echo = false}
    end
  end
end
