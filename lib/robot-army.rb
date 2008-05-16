%w[rubygems open3 base64 thor ruby2ruby].each do |library|
  require library
end

%w[loader soldier messenger task_master ruby2ruby_ext].each do |file|
  require File.join(File.dirname(__FILE__), 'robot-army', file)
end

def debug(*whatever)
  File.open('/tmp/robot-army', 'a') { |f| f.puts "[#{Process.pid}] #{whatever.join(' ')}" }
end
