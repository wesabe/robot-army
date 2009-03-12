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
    # @raise Errno::EACCES
    #   If the destination path cannot be written to.
    #
    # @raise Errno::ENOENT
    #   If the source path cannot be read.
    #
    def scp(src, dest, hosts=self.hosts)
      Array(hosts).each do |host|
        output = `scp -q #{src} #{"#{host}:" unless host == :localhost}#{dest} 2>&1`
        case output
        when /Permission denied/i
          raise Errno::EACCES, output.chomp
        when /No such file or directory/i
          raise Errno::ENOENT, output.chomp
        end unless $?.exitstatus == 0
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

      results = remote(hosts, options) do
        File.join(%x{mktemp -d -t robot-army.XXXX}.chomp, File.basename(path))
      end

      me = ENV['USER']
      host_and_path = Array(hosts).zip(Array(results))
      # copy them over
      host_and_path.each do |host, tmp|
        sudo(host) { FileUtils.chown(me, nil, File.dirname(tmp)) } if options[:user]
        scp path, tmp, host
        sudo(host) { FileUtils.chown(options[:user], nil, File.dirname(tmp)) } if options[:user]
      end
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
      evaler = RemoteEvaler.new(connection(options[:host]), EvalCommand.new do |command|
        command.proc = proc
        command.args = options[:args] || []
        command.context = self
        command.dependencies = @dep_loader
      end)

      return evaler.execute_command
    end
  end
end
