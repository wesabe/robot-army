# Determines whether a given object can be dumped.
# 
# ==== Parameters
# object<Object>:: The object to check.
# 
# ==== Returns
# true, false::
#   true if dumping the object does not raise an error, 
#   false if a +TypeError+ is raised.
# 
# ==== Raises
# Exception::
#   Whatever Marshal.dump might raise that isn't a +TypeError+.
# 
# @public
def Marshal.can_dump?(object)
  begin
    Marshal.dump(object)
    return true
  rescue TypeError
    return false
  end
end

class Object
  # Syntactic sugar for +Marshal.can_dump?+.
  def marshalable?
    Marshal.can_dump?(self)
  end
end
