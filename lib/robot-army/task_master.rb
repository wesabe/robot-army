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
    
    # Gets or sets a single host that instances of +RobotArmy::TaskMaster+ subclasses will use.
    # 
    # @param host [String, :localhost]
    #   The fully-qualified domain name to connect to.
    # 
    # @return [String, :localhost]
    #   The current value for the host.
    # 
    # @raise RobotArmy::HostArityError
    #   If you're using the getter form of this method and you've already 
    #   set multiple hosts, an error will be raised.
    # 
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
    
    # Gets or sets the hosts that instances of +RobotArmy::TaskMaster+ subclasses will use.
    # 
    # @param hosts [Array[String]]
    #   A list of fully-qualified domain names to connect to.
    # 
    # @return [Array[String]]
    #   The current list of hosts.
    # 
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
    
    # Gets the first host for this instance of +RobotArmy::TaskMaster+.
    # 
    # @return [String, :localhost]
    #   The host value to use.
    # 
    # @raise RobotArmy::HostArityError
    #   If you're using the getter form of this method and you've already 
    #   set multiple hosts, an error will be raised.
    # 
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
    
    # Sets a single host for this instance of +RobotArmy::TaskMaster+.
    # 
    # @param host [String, :localhost]
    #   The host value to use.
    # 
    def host=(host)
      @hosts = nil
      @host = host
    end
    
    # Gets the hosts for the instance of +RobotArmy::TaskMaster+.
    # 
    # @return [Array[String]]
    #   A list of hosts.
    # 
    def hosts
      if @hosts
        @hosts
      elsif @host
        [@host]
      else
        self.class.hosts
      end
    end
    
    # Sets the hosts for this instance of +RobotArmy::TaskMaster+.
    # 
    # @param hosts [Array[String]]
    #   A list of hosts.
    # 
    def hosts=(hosts)
      @host = nil
      @hosts = hosts
    end
    
    # Gets an open connection for the host this instance is configured to use.
    # 
    # @return RobotArmy::Connection
    #   An open connection with an active Ruby process.
    # 
    def connection(host)
      RobotArmy::GateKeeper.shared_instance.connect(host)
    end
    
    # Runs a block of Ruby on the machine specified by a host string as root 
    # and returns the return value of the block. Example:
    # 
    #   sudo { `shutdown -r now` }
    # 
    # You may also specify a user other than root. In this case +sudo+ is the
    # same as +remote+:
    # 
    #   sudo(:user => 'www-data') { `/etc/init.d/apache2 restart` }
    # 
    # @param host [String, :localhost]
    #   The fully-qualified domain name of the machine to connect to, or 
    #   +:localhost+ if you want to use the same machine.
    # 
    # @options options
    #   :user -> String => shell user
    # 
    # @raise Exception
    #   Whatever is raised by the block.
    # 
    # @return [Object]
    #   Whatever is returned by the block.
    # 
    # @see remote
    def sudo(hosts=self.hosts, options={}, &proc)
      options, hosts = hosts, self.hosts if hosts.is_a?(Hash)
      remote hosts, {:user => 'root'}.merge(options), &proc
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
    # Objects which can't be marshalled, such as IO streams, will be proxied 
    # instead:
    # 
    #   file = File.open("README.markdown", "r")
    #   remote { file.gets } # => "Robot Army\n"
    # 
    # @param hosts [HostList]
    #   Which hosts to run the block on.
    # 
    # @options options
    #   :user -> String => shell user
    # 
    # @raise Exception
    #   Whatever is raised by the block.
    # 
    # @return [Object]
    #   Whatever is returned by the block.
    # 
    def remote(hosts=self.hosts, options={}, &proc)
      options, hosts = hosts, self.hosts if hosts.is_a?(Hash)
      results = Array(hosts).map {|host| remote_eval({:host => host}.merge(options), &proc) }
      results.size == 1 ? results.first : results
    end
    
    # Copies src to dest on each host.
    # 
    # @param src [String]
    #   A local file to copy.
    # 
    # @param dest [String]
    #   The path of a remote file to copy to.
    # 
    def scp(src, dest, hosts=self.hosts)
      Array(hosts).each do |host|
        system "scp #{src} #{"#{host}:" unless host == :localhost}#{dest}"
      end
      
      return nil
    end
    
    # Copies path to a temporary directory on each host.
    # 
    # @param path [String]
    #   A local file to copy.
    # 
    # @param hosts [HostList]
    #   Which hosts to connect to.
    # 
    # @yield [path]
    #   Yields the path of the newly copied file on each remote host.
    # 
    # @yieldparam [String] path
    #   The path of the file under in a new directory under a 
    #   temporary directory on the remote host.
    # 
    # @return [Array<String>]
    #   An array of destination paths.
    # 
    def cptemp(path, hosts=self.hosts, options={}, &block)
      hosts, options = self.hosts, hosts if hosts.is_a?(Hash)
      
      results = remote(hosts) do
        File.join(%x{mktemp -d -t robot-army.XXXX}.chomp, File.basename(path))
      end
      
      host_and_path = Array(hosts).zip(Array(results))
      # copy them over
      host_and_path.each { |host, tmp| scp path, tmp, host }
      # call the block on each host
      results = host_and_path.map do |host, tmp|
        remote(host, options.merge(:args => [tmp]), &block)
      end if block
      
      results.size == 1 ? results.first : results
    end
    
    # Add a gem dependency this TaskMaster checks for on each remote host.
    # 
    # @param dep [String]
    #   The name of the gem to check for.
    # 
    # @param ver [String]
    #   The version string of the gem to check for.
    # 
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
    # @param names [Array[String]]
    #   The names of the variables to dump.
    # 
    # @yield [name, index]
    #   Yields the name and its index and expects 
    #   to get the corresponding value.
    # 
    # @yieldparam [String] name
    #   The name of the value for the block to return.
    # 
    # @yieldparam [Fixnum] index
    #   The index of the value for the block to return.
    # 
    # @return [(Array[Object], Hash[Fixnum => Object])]
    #   The pair +values+ and +proxies+.
    # 
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
    # @options options
    #   :host -> [String, :localhost] => remote host
    #   :user -> String => shell user
    #   :password -> [String, nil] => sudo password
    # 
    # @return Object
    #   Whatever the block returns.
    # 
    # @raise Exception
    #   Whatever the block raises.
    # 
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
            if data.marshalable?
              conn.post :status => 'ok', :data => data
            else
              proxies[data.hash] = data
              conn.post :status => 'proxy', :data => data.hash
            end
          rescue Object => e
            conn.post :status => 'error', :data => e
          end
        when 'password'
          conn.post :status => 'ok', :data => ask_for_password(host, response[:data])
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
    
    def ask_for_password(host, data={})
      require 'highline'
      HighLine.new.ask("[sudo] password for #{data[:user]}@#{host}: ") {|q| q.echo = false}
    end
  end
end
