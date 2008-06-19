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
    # ==== Raises
    # RobotArmy::HostArityError::
    #   If you're using the getter form of this method and you've already 
    #   set multiple hosts, an error will be raised.
    # 
    # ==== Alternatives
    # If no argument is provided just returns the current host.
    # 
    # @public
    def self.host(host=nil)
      if host
        @hosts = nil
        @host = host
      elsif @hosts
        raise RobotArmy::HostArityError, 
          "There are #{@hosts.size} hosts, so calling host doesn't make sense"
      else
        @host
      end
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
      if hosts
        @host = nil
        @hosts = hosts
      elsif @host
        [@host]
      else
        @hosts || []
      end
    end
    
    # Gets the first host for this instance of +TaskMaster+.
    # 
    # ==== Returns
    # String, nil:: The host value to use.
    # 
    # ==== Raises
    # RobotArmy::HostArityError::
    #   If you're using the getter form of this method and you've already 
    #   set multiple hosts, an error will be raised.
    # 
    # @public
    def host
      if @host
        @host
      elsif @hosts
        raise RobotArmy::HostArityError, 
          "There are #{@hosts.size} hosts, so calling host doesn't make sense"
      else
        self.class.host
      end
    end
    
    # Sets a single host for this instance of +TaskMaster+.
    # 
    # ==== Parameters
    # host<String, nil>:: The host value to use.
    # 
    # @public
    def host=(host)
      @hosts = nil
      @host = host
    end
    
    # Gets the hosts for the instance of +TaskMaster+.
    # 
    # ==== Returns
    # Array[String]:: A list of hosts.
    # 
    # @public
    def hosts
      if @hosts
        @hosts
      elsif @host
        [@host]
      else
        self.class.hosts
      end
    end
    
    # Sets the hosts for this instance of +TaskMaster+.
    # 
    # ==== Parameters
    # hosts<Array[String]>:: A list of hosts.
    # 
    # @public
    def hosts=(hosts)
      @host = nil
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
      options, hosts = hosts, self.hosts if hosts.is_a?(Hash)
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
      Array(hosts).each do |host|
        system "scp #{src} #{"#{host}:" unless host == :localhost}#{dest}"
      end
      
      return nil
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
    def cptemp(path, hosts=self.hosts, &block)
      results = remote(hosts) do
        File.join(%x{mktemp -d -t robot-army}.chomp, File.basename(path))
      end
      
      host_and_path = Array(hosts).zip(Array(results))
      # copy them over
      host_and_path.each { |host, tmp| scp path, tmp, host }
      # call the block on each host
      results = host_and_path.map { |host, tmp| remote(host, :args => [tmp], &block) } if block
      
      results.size == 1 ? results.first : results
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
    
    # Dumps the values associated with the given names for transport.
    # 
    # ==== Parameters
    # names<Array[String]>:: The names of the variables to dump.
    # 
    # ==== Yields
    # [String, Fixnum]:: The name and index of a value, should get back a value.
    # 
    # ==== Returns
    # [Array[Object], Hash[Fixnum => Object]]:: The pair +values+ and +proxies+.
    # 
    # @private
    def dump_values(names)
      proxies = {}
      values = []
      
      names.each_with_index do |name, i|
        value = yield name, i
        if value.marshalable?
          dump = Marshal.dump(value)
          values << "#{name} = Marshal.load(#{dump.inspect})"
        else
          proxies[value.hash] = value
          values << "#{name} = #{RobotArmy::Proxy.generator_for(value)}"
        end
      end
      
      return values, proxies
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
      procargs = options[:args] || []
      proxies  = { self.hash => self }
      
      ##
      ## build the code to send it
      ##
      
      # fix stack traces
      file, line = eval('[__FILE__, __LINE__]', proc.binding)
      
      # include local variables
      local_variables = eval('local_variables', proc.binding)
      locals, lproxies = dump_values(local_variables) { |name,| eval(name, proc.binding) }
      proxies.merge! lproxies
      
      # include arguments
      args, aproxies = dump_values(proc.arguments) { |_, i| procargs[i] }
      proxies.merge! aproxies
      
      # include dependency loader
      dep_loading = "Marshal.load(#{Marshal.dump(@dep_loader).inspect}).load!"
      
      # get the code for the proc
      proc = "proc{ #{proc.to_ruby(true)} }"
      messenger = "RobotArmy::Messenger.new($stdin, $stdout)"
      context = "RobotArmy::Proxy.new(#{messenger}, #{self.hash.inspect})"
      
      code = %{
        #{dep_loading} # load dependencies
        #{(locals+args).join("\n")} # all local variables
        #{context}.__proxy_instance_eval(&#{proc}) # run the block
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
