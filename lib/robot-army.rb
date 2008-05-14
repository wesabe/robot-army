%w[robot].each do |file|
  require File.join(File.dirname(__FILE__), 'robot-army', 'robot')
end
