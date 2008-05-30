%w[rubygems open3 base64 thor ruby2ruby].each do |library|
  require library
end

module RobotArmy
  class ConnectionNotOpen < StandardError; end
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
end

%w[loader officer_loader 
   soldier officer 
   messenger task_master 
   connection officer_connection 
   marshal_wrapper
   gate_keeper ruby2ruby_ext].each do |file|
  require File.join(File.dirname(__FILE__), 'robot-army', file)
end

at_exit do
  RobotArmy::GateKeeper.shared_instance.close
end

def debug(*whatever)
  File.open('/tmp/robot-army', 'a') { |f| f.puts "[#{Process.pid}] #{whatever.join(' ')}" }
end
