require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::IO, 'class method read_data' do
  before do
    @stream = stub(:stream)
  end
  
  it "reads all data as long as it is available" do
    RobotArmy::IO.stub!(:has_data?).and_return(true, true, false)
    @stream.stub!(:readpartial).and_return('foo', 'bar')
    
    RobotArmy::IO.read_data(@stream).should == "foobar"
  end
end

describe RobotArmy::IO do
  before do
    @stream = RobotArmy::IO.new(:stdout)
    @upstream = RobotArmy.upstream = stub(:upstream)
  end
  
  it "can capture output of IO method calls" do
    @stream.send(:capture, :print, 'foo').should == 'foo'
  end
  
  it "proxies output upstream" do
    @upstream.should_receive(:post).
      with(:status => 'output', :data => {:stream => 'stdout', :string => "foo\n"})
    
    @stream.puts 'foo'
  end
  
  after do
    @stream.stop_capture
  end
end
