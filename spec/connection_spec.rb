require File.dirname(__FILE__) + '/spec_helper'

describe RobotArmy::Connection do
  before do
    # given
    @host = 'example.com'
    @connection = RobotArmy::Connection.new(@host)
    @messenger  = mock(:messenger)
    @messenger.stub!(:post)
    @connection.stub!(:messenger).and_return(@messenger)
    @connection.stub!(:start_child)
  end

  it "is not closed after opening" do
    # when
    @connection.open

    # then
    @connection.should_not be_closed
  end

  it "returns itself from open" do
    @connection.open.should == @connection
  end

  it "returns the result of the block passed to open" do
    # when
    @connection.stub!(:close)

    # then
    @connection.open{ 3 }.should == 3
  end

  it "closes the connection if a block is passed to open" do
    # then
    proc{ @connection.open{ 3 } }.
      should_not change(@connection, :closed?).from(true)
  end

  it "closes the connection even if an exception is raised in the block passed to open" do
    # then
    proc do
      proc{ @connection.open{ raise 'BOO!' } }.
        should_not change(@connection, :closed?).from(true)
    end.
      should raise_error('BOO!')
  end

  it "does not start another child process if we're already open" do
    # then
    @connection.should_not_receive(:start_child)

    # when
    @connection.stub!(:closed?).and_return(false)
    @connection.open
  end

  it "raises an exception when calling close if a connection is already closed" do
    # when
    @connection.stub!(:closed?).and_return(true)

    # then
    proc{ @connection.close }.should raise_error(RobotArmy::ConnectionNotOpen)
  end

  it "sends an exit command to its child upon closing" do
    # then
    @messenger.should_receive(:post).with(:command => :exit)

    # when
    @connection.stub!(:closed?).and_return(false)
    @connection.close
  end

  it "starts a closed local connection when calling localhost" do
    RobotArmy::Connection.localhost.should be_closed
  end

  it "raises a Warning when handling a message with status=warning" do
    proc{ @connection.handle_response(:status => 'warning', :data => 'foobar') }.
      should raise_error(RobotArmy::Warning)
  end
end

describe RobotArmy::Connection, 'answer_sudo_prompt' do
  before do
    @connection = RobotArmy::Connection.new(:localhost, 'root')
    @password_proc = proc { 'password' }
    @stdin = StringIO.new
    @stderr = stub(:stderr, :readpartial => nil)
  end

  it "calls back using the password proc if it is a proc" do
    # when
    @connection.stub!(:password).and_return(@password_proc)
    @connection.stub!(:asking_for_password?).and_return(true, false)
    @connection.answer_sudo_prompt(@stdin, @stderr)

    # then
    @stdin.string.should == "password\n"
  end

  it "raises if password is a string and is rejected" do
    # when
    @connection.stub!(:password).and_return('password')
    @connection.stub!(:asking_for_password?).and_return(true)

    # then
    proc { @connection.answer_sudo_prompt(@stdin, @stderr) }.
      should raise_error(RobotArmy::InvalidPassword)
  end

  it "calls back three times before raising if password is a proc" do
    calls = 0

    # when
    @connection.stub!(:password).and_return(proc{ calls += 1 })

    # then
    @connection.should_receive(:asking_for_password?).
      exactly(4).times.and_return(true)
    proc { @connection.answer_sudo_prompt(@stdin, @stderr) }.
      should raise_error(RobotArmy::InvalidPassword)
    calls.should == 3
  end
end
