module RobotArmy
  class Messenger
    attr_reader :input, :output
    
    def initialize(input, output)
      @input, @output = input, output
    end
    
    def post(response)
      dump = Marshal.dump(response)
      output.puts dump.size
      output << dump
    end
    
    def get
      size = input.gets.chomp.to_i
      Marshal.load(input.read(size))
    end
  end
end
