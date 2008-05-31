%w[rubygems open3 base64 thor ruby2ruby].each do |library|
  require library
end

module RobotArmy
  class ConnectionNotOpen < StandardError; end
  class InvalidPassword < StandardError
    def message
      "Invalid password"
    end
  end
  class RobotArmy::Exit < Exception
    attr_accessor :status
    
    def initialize(status=0)
      @status = status
    end
  end
  
  CHARACTERS = %w[a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9]
  
  # Generates a random string of lowercase letters and numbers.
  # 
  # ==== Parameters
  # length<Fixnum>:: The length of the string to generate.
  # 
  # ==== Returns
  # String:: The random string.
  # 
  # @public
  def self.random_string(length=16)
    (0...length).map{ CHARACTERS[rand(CHARACTERS.size)] }.join
  end
  
  # Determines whether the given stream has any data to be read.
  # 
  # ==== Parameters
  # stream<IO>:: The IO stream to check.
  # 
  # ==== Returns
  # Boolean:: true if stream has data to be read, false otherwise.
  # 
  # @public
  def self.has_data?(stream)
    selected, _ = IO.select([stream], nil, nil, 0.5)
    return selected && !selected.empty?
  end
  
  # Reads immediately available data from the given stream.
  # 
  # ==== Parameters
  # stream<IO>:: The IO stream to read from.
  # 
  # ==== Returns
  # String:: The data read from the stream.
  # 
  # @public
  def self.read_data(stream)
    data = []
    data << stream.readpartial(1024) while has_data?(stream)
    return data.join
  end
end

%w[loader officer_loader 
   soldier officer 
   messenger task_master 
   connection officer_connection 
   marshal_wrapper dependency_loader
   gate_keeper ruby2ruby_ext].each do |file|
  require File.join(File.dirname(__FILE__), 'robot-army', file)
end

at_exit do
  RobotArmy::GateKeeper.shared_instance.close
end

def debug(*whatever)
  File.open('/tmp/robot-army', 'a') { |f| f.puts "[#{Process.pid}] #{whatever.join(' ')}" }
end
