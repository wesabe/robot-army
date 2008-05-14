$TESTING=true
load File.join(File.dirname(__FILE__), '..', 'lib', 'robot-army.rb')

module Spec::Expectations::ObjectExpectations
  alias_method :must, :should
  alias_method :must_not, :should_not
  undef_method :should
  undef_method :should_not
end

class StreamCapturer
  attr_reader :output

  def initialize
    @output = StringIO.new
  end
  
  %w[stderr stdout].each do |stream|
    class_eval <<-RUBY
    def self.capture_#{stream}(&block)
      new.capture_#{stream}(&block)
    end
    
    def capture_#{stream}
      begin
        old = $#{stream}
        $#{stream} = output
        yield
      ensure
        $#{stream} = old
      end
      output.string
    end
    RUBY
  end
end

Spec::Runner.configure do |config|
  def stdout_from(&block)
    StreamCapturer.capture_stdout(&block)
  end
  
  def stderr_from(&block)
    StreamCapturer.capture_stderr(&block)
  end
  
  alias silence_stdout stdout_from
  alias silence_stderr stderr_from
end
