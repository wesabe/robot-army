class RobotArmy::IO
  attr_reader :name
  
  # Starts capturing output of the named stream.
  # 
  def start_capture
    eval "$#{name} = self"
  end
  
  # Stops capturing output of the named stream.
  # 
  def stop_capture
    eval "$#{name} = #{name.upcase}"
  end
  
  def puts(*args) #:nodoc:
    post capture(:puts, *args)
  end
  
  def print(*args) #:nodoc:
    post capture(:print, *args)
  end
  
  def write(*args) #:nodoc:
    post capture(:write, *args)
  end
  
private
  
  def initialize(name)
    @name = name.to_s
    start_capture
  end
  
  def post(string)
    RobotArmy.upstream.post(:status => 'output', :data => {:stream => name, :string => string})
  end
  
  def capture(*call)
    stream = StringIO.new
    stream.send(*call)
    stream.string
  end
  
  class <<self
    # Determines whether the given stream has any data to be read.
    # 
    # @param stream [IO]
    #   The +IO+ stream to check.
    # 
    # @return [Boolean]
    #   +true+ if stream has data to be read, +false+ otherwise.
    # 
    def has_data?(stream)
      selected, _ = IO.select([stream], nil, nil, 0.5)
      return selected && !selected.empty?
    end

    # Reads immediately available data from the given stream.
    # 
    #   # echo foo | ruby test.rb
    #   RobotArmy::IO.read_data($stdin) # => "foo\n"
    # 
    # @param stream [IO]
    #   The +IO+ stream to read from.
    # 
    # @return [String]
    #   The data read from the stream.
    # 
    def read_data(stream)
      data = []
      data << stream.readpartial(1024) while has_data?(stream)
      return data.join
    end
    
    # Redirects the named stream to a +StringIO+.
    # 
    #   RobotArmy::IO.capture(:stdout) { puts "foo" } # => "foo\n"
    # 
    #   RobotArmy::IO.silence(:stderr) { system "rm non-existent-file" }
    # 
    # @param stream [Symbol]
    #   The name of the stream to redirect (i.e. +:stderr+, +:stdout+).
    # 
    # @yield
    #   The block whose output we should capture.
    # 
    # @return [String]
    #   The string result of the output produced by the block.
    # 
    def capture(stream)
      begin
        stream = stream.to_s
        eval "$#{stream} = StringIO.new"
        yield
        result = eval("$#{stream}").string
      ensure 
        eval("$#{stream} = #{stream.upcase}")
      end

      result
    end
    
    alias_method :silence, :capture
  end
end
