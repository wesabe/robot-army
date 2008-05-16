module RobotArmy
  class Messenger
    attr_reader :input, :output
    
    def initialize(input, output)
      @input, @output = input, output
    end
    
    def post(response)
      debug "post(#{response.inspect})"
      dump = Marshal.dump(response)
      dump = Base64.encode64(dump) + '|'
      output << dump
    end
    
    def get
      data = nil
      loop do
        case data = input.gets('|')
        when nil, ''
          return nil
        when /^\s*$/
          # again!
        else
          break
        end
      end
      data = Base64.decode64(data.chop)
      Marshal.load(data)
    end
  end
end
