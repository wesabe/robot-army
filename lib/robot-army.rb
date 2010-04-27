require 'rubygems'
require 'open3'
require 'base64'
require 'thor'

gem 'ParseTree', '>=3'
require 'parse_tree'

gem 'ruby2ruby', '>=1.2.0'
require 'ruby2ruby'
require 'parse_tree_extensions'

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
  class RobotArmy::ShellCommandError < RuntimeError
    attr_reader :command, :exitstatus, :output

    def initialize(command, exitstatus, output)
      @command, @exitstatus, @output = command, exitstatus, output
      super "command failed with exit status #{exitstatus}: #{command}"
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

  def self.ask_for_password(host, data={})
    require 'highline'
    HighLine.new.ask("[sudo] password for #{data[:user]}@#{host}: ") {|q| q.echo = false}
  end
end

$LOAD_PATH << File.dirname(__FILE__)

require 'robot-army/loader'
require 'robot-army/dependency_loader'
require 'robot-army/io'
require 'robot-army/officer_loader'
require 'robot-army/soldier'
require 'robot-army/officer'
require 'robot-army/messenger'
require 'robot-army/task_master'
require 'robot-army/proxy'
require 'robot-army/eval_builder'
require 'robot-army/eval_command'
require 'robot-army/remote_evaler'
require 'robot-army/keychain'
require 'robot-army/connection'
require 'robot-army/officer_connection'
require 'robot-army/marshal_ext'
require 'robot-army/gate_keeper'
require 'robot-army/at_exit'
require 'robot-army/ruby2ruby_ext'

at_exit do
  RobotArmy::AtExit.shared_instance.do_exit
  RobotArmy::GateKeeper.shared_instance.close
end

def debug(*whatever)
  File.open('/tmp/robot-army.log', 'a') do |f|
    f.puts "[#{Process.pid}] #{whatever.join(' ')}"
  end if $TESTING || $ROBOT_ARMY_DEBUG
end
