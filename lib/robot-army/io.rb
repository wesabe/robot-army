class RobotArmy::IO
  class <<self
    # Determines whether the given stream has any data to be read.
    # 
    # @param stream [IO]
    #   The +IO+ stream to check.
    # 
    # @return [Boolean]
    #   +true+ if stream has data to be read, +false+ otherwise.
    # 
    def self.has_data?(stream)
      selected, _ = IO.select([stream], nil, nil, 0.5)
      return selected && !selected.empty?
    end

    # Reads immediately available data from the given stream.
    # 
    # @param stream [IO]
    #   The +IO+ stream to read from.
    # 
    # @return [String]
    #   The data read from the stream.
    # 
    def self.read_data(stream)
      data = []
      data << stream.readpartial(1024) while has_data?(stream)
      return data.join
    end
  end
end
