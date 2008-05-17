class RobotArmy::GateKeeper
  def connect(host)
    connections[host] ||= establish_connection(host)
  end
  
  def establish_connection(host)
    connection = connections[host] = RobotArmy::Connection.new(host)
    connection.open
  end
  
  def connections
    @connections ||= {}
  end
  
  def close
    connections.each { |host,c| c.close unless c.closed? }
  end
  
  def self.shared_instance
    @shared_instance ||= new
  end
end
