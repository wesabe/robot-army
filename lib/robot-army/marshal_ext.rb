module Marshal
  class <<self
    # Determines whether a given object can be dumped.
    #
    # @param object Object
    #   The object to check.
    #
    # @return [Boolean]
    #   +true+ if dumping the object does not raise an error,
    #   +false+ if a +TypeError+ is raised.
    #
    # @raise Exception
    #   Whatever +Marshal.dump+ might raise that isn't a +TypeError+.
    #
    def can_dump?(object)
      begin
        Marshal.dump(object)
        return true
      rescue TypeError
        return false
      end
    end
  end
end

class Object
  # Syntactic sugar for +Marshal.can_dump?+.
  #
  # @see Marshal.can_dump?
  def marshalable?
    Marshal.can_dump?(self) &&
    instance_variables.all? do |ivar|
      instance_variable_get(ivar).marshalable?
    end
  end
end

class Array
  def marshalable?
    super &&
    all? {|item| item.marshalable?}
  end
end

class Hash
  def marshalable?
    super &&
    keys.marshalable? &&
    values.marshalable? &&
    default.marshalable?
  end
end
