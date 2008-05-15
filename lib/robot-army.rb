%w[soldier messenger task_master].each do |file|
  require File.join(File.dirname(__FILE__), 'robot-army', file)
end
