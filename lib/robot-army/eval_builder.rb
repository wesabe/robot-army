class RobotArmy::EvalBuilder
  def self.build(command)
    new.build(command)
  end

  def build(command)
    proc, procargs, context, dependencies =
      command.proc, command.args, command.context, command.dependencies

    options = {}
    proxies = {context.hash => context}

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
    dep_loading = "Marshal.load(#{Marshal.dump(dependencies).inspect}).load!"

    # get the code for the proc
    proc = "proc{ #{proc.to_ruby_without_proc_wrapper} }"
    messenger = "RobotArmy::Messenger.new($stdin, $stdout)"
    context = "RobotArmy::Proxy.new(#{messenger}, #{context.hash.inspect})"

    code = %{
      #{dep_loading} # load dependencies
      #{(locals+args).join("\n")} # all local variables
      #{context}.__proxy_instance_eval(&#{proc}) # run the block
    }

    options[:file] = file
    options[:line] = line
    options[:code] = code
    options[:user] = command.user if command.user

    return options, proxies
  end

  private

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
end
