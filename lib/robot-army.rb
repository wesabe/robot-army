require 'rubygems'
require 'open3'
require 'base64'
require 'thor'
gem 'ruby2ruby', '=1.1.9'
require 'ruby2ruby'
require 'fileutils'

module RobotArmy
  # Gets the upstream messenger.
  # 
  # @return [RobotArmy::Messenger]
  #   A messenger connection pointing upstream.
  # 
  def self.upstream
    @upstream
  end
  
  # Sets the upstream messenger.
  # 
  # @param messenger [RobotArmy::Messenger]
  #   A messenger connection pointing upstream.
  # 
  def self.upstream=(messenger)
    @upstream = messenger
  end
  
  class ConnectionNotOpen < StandardError; end
  class Warning < StandardError; end
  class HostArityError < StandardError; end
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
  # @param length [Fixnum]
  #   The length of the string to generate.
  # 
  # @return [String]
  #   The random string.
  # 
  def self.random_string(length=16)
    (0...length).map{ CHARACTERS[rand(CHARACTERS.size)] }.join
  end
end

%w[loader dependency_loader io 
   officer_loader soldier officer 
   messenger task_master proxy 
   connection officer_connection 
   marshal_ext gate_keeper ruby2ruby_ext].each do |file|
  require File.join(File.dirname(__FILE__), 'robot-army', file)
end

at_exit do
  RobotArmy::GateKeeper.shared_instance.close
end

def debug(*whatever)
  File.open('/tmp/robot-army.log', 'a') do |f|
    f.puts "[#{Process.pid}] #{whatever.join(' ')}"
  end if $VERBOSE
end
