#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '..', 'lib', 'robot-army')

class Whoami < RobotArmy::TaskMaster
  desc 'test', "Tests whoami"
  method_options :root => :boolean, :host => :string
  def test(options={})
    self.host = options['host']
    puts options['root'] ?
      sudo{ `whoami` } :
      remote{ `whoami` }
  end
end
