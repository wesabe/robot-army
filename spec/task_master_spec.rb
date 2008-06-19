require File.dirname(__FILE__) + '/spec_helper'

class Example < RobotArmy::TaskMaster
  hosts %[www1.example.com www2.example.com]
end

class Localhost < RobotArmy::TaskMaster
  host :localhost
end

describe RobotArmy::TaskMaster, 'host management' do
  before do
    @example = Example.new
  end
  
  it "allows setting a single host" do
    Example.host 'example.com'
    Example.host.must == 'example.com'
  end
  
  it "allows accessing multi-hosts when using the single-host interface" do
    Example.host 'example.com'
    Example.hosts.must == %w[example.com]
  end
  
  it "allows setting multiple hosts on the class" do
    Example.hosts %w[example.com test.com]
    Example.hosts.must == %w[example.com test.com]
  end
  
  it "denies accessing a single host when using the multi-host interface" do
    Example.hosts %w[example.com test.com]
    proc { Example.host }.must raise_error(
      RobotArmy::HostArityError, "There are 2 hosts, so calling host doesn't make sense")
  end
  
  it "instances default to the hosts set on the class" do
    Example.host 'example.com'
    @example.host.must == 'example.com'
    
    Example.hosts %w[example.com test.com]
    @example.hosts.must == %w[example.com test.com]
  end
  
  it "allows setting a single host on an instance" do
    @example.host = 'example.com'
    @example.host.must == 'example.com'
  end
  
  it "allows accessing multi-hosts when using the single-host interface on instances" do
    @example.host = 'example.com'
    @example.hosts.must == %w[example.com]
  end
  
  it "allows setting multiple hosts on an instance" do
    @example.hosts = %w[example.com test.com]
    @example.hosts.must == %w[example.com test.com]
  end
  
  it "denies accessing a single host when using the multi-host interface" do
    @example.hosts = %w[example.com test.com test2.com]
    proc { @example.host }.must raise_error(
      RobotArmy::HostArityError, "There are 3 hosts, so calling host doesn't make sense")
  end
end

describe RobotArmy::TaskMaster, 'remote' do
  before do
    @localhost = Localhost.new
    @example   = Example.new
  end
  
  it "returns a single item when using the single-host interface" do
    @localhost.stub!(:remote_eval).and_return(7)
    @localhost.remote { 3+4 }.must == 7
  end
  
  it "returns an array of items when using the multi-host interface" do
    @example.stub!(:remote_eval).and_return(7)
    @example.remote { 3+4 }.must == [7, 7]
  end
end

describe RobotArmy::TaskMaster do
  before do
    @localhost = Localhost.new
    @example = Example.new
  end
  
  it "runs a remote block on each host" do
    @example.should_receive(:remote_eval).exactly(2).times
    @example.remote { 3+4 }
  end
  
  
  it "can execute a Ruby block and return the result" do
    @localhost.remote { 3+4 }.must == 7
  end
  
  it "executes its block in a different process" do
    @localhost.remote { Process.pid }.must_not == Process.pid
  end
  
  it "preserves local variables" do
    a = 42
    @localhost.remote { a }.must == 42
  end
  
  it "warns about invalid remote return values" do
    capture(:stderr) { @localhost.remote { $stdin } }.
      must =~ /WARNING: ignoring invalid remote return value/
  end
  
  it "returns nil if the remote return value is invalid" do
    silence(:stderr) { @localhost.remote { $stdin }.must be_nil }
  end
  
  it "re-raises exceptions thrown remotely" do
    proc { @localhost.remote { raise ArgumentError, "You fool!" } }.
      must raise_error(ArgumentError)
  end
  
  it "prints the child Ruby's stderr to stderr" do
    pending('we may not want to do this, even')
    capture(:stderr) { @localhost.remote { $stderr.print "foo" } }.must == "foo"
  end
  
  it "runs multiple remote blocks for the same host in different processes" do
    @localhost.remote { $a = 1 }
    @localhost.remote { $a }.must be_nil
  end
  
  it "only loads one Officer process on the remote machine" do
    info = @localhost.connection(@localhost.host).info
    info[:pid].must_not == Process.pid
    info[:type].must == 'RobotArmy::Officer'
    @localhost.connection(@localhost.host).info.must == info
  end
  
  it "runs as a normal (non-super) user by default" do
    @localhost.remote{ Process.uid }.must_not == 0
  end
  
  it "allows running as super-user" do
    pending('figure out a way to run this only sometimes')
    @localhost.sudo{ Process.uid }.must == 0
  end
  
  it "loads dependencies" do
    @localhost.dependency "thor"
    @localhost.remote { Thor ; 45 }.must == 45 # loading should not bail here
  end
  
  it "delegates scp to the scp binary" do
    @localhost.should_receive(:system).with('scp file.tgz example.com:/tmp')
    @localhost.host = 'example.com'
    @localhost.scp 'file.tgz', '/tmp'
  end
  
  it "delegates to scp without a host when host is localhost" do
    @localhost.should_receive(:system).with('scp file.tgz /tmp')
    @localhost.scp 'file.tgz', '/tmp'
  end
end

describe RobotArmy::TaskMaster, 'remote (with args)' do
  before do
    @localhost = Localhost.new
  end
  
  it "can pass arguments explicitly" do
    @localhost.remote(:args => [42]) { |a| a }.must == 42
  end
  
  it "shadows local variables of the same name" do
    a = 23
    @localhost.remote(:args => [42]) { |a| a }.must == 42
  end
end

describe RobotArmy::TaskMaster, 'cptemp' do
  before do
    @localhost = Localhost.new
    @path = 'cptemp-spec-file'
    File.open(@path, 'w') {|f| f << 'testing'}
  end
  
  it "safely copies to a new temporary directory" do
    destination = @localhost.cptemp @path
    File.read(destination).must == 'testing'
  end
  
  it "yields the path to each host if a block is passed" do
    path, pid = @localhost.cptemp(@path) { |path| [path, Process.pid] }
    File.basename(path).must == @path
    pid.must_not be_nil
    pid.must_not == Process.pid
  end
  
  it "allow running as another user" do
    pending("how should I even test this?")
  end
  
  after do
    FileUtils.rm_f(@path)
  end
end

describe RobotArmy::TaskMaster, 'with proxies' do
  before do
    @localhost = Localhost.new
  end
  
  it "can allow remote method calls on the local object" do
    def @localhost.foo; 'bar'; end
    @localhost.remote { foo }.must == 'bar'
  end
  
  it "allows calling methods with arguments" do
    def @localhost.echo(o) o; end
    @localhost.remote { echo 42 }.must == 42
  end
  
  it "allows passing a block to method calls on proxy objects" do
    pending('this is insane. should I do this?')
  end
  
  it "allows interaction with IOs" do
    capture(:stdout) {
      stdout = $stdout
      @localhost.remote { stdout.puts "hey there" }
    }.must == "hey there\n"
  end
  
  it "returns a proxy if the return value of an upstream call can't be marshaled" do
    def @localhost.stdout; $stdout; end
    capture(:stdout) { @localhost.remote { stdout.puts "foo" } }.must == "foo\n"
  end
end

describe RobotArmy::TaskMaster, 'sudo' do
  before do
    @localhost = Localhost.new
  end
  
  it "runs remote with the root user by default" do
    @localhost.should_receive(:remote).
      with(@localhost.hosts, :user => 'root')
    
    @localhost.sudo { File.read('/etc/passwd') }
  end
  
  it "allows specifying a particular user" do
    @localhost.should_receive(:remote).
      with(@localhost.hosts, :user => 'www-data')
    
    @localhost.sudo(:user => 'www-data') { %x{/etc/init.d/apache2 restart} }
  end
end