class Proc
  def arguments
    (to_ruby[/\Aproc \{ \|([^\|]+)\|/, 1] || '').split(/\s*,\s*/)
  end

  def to_ruby_without_proc_wrapper
    to_ruby[/\Aproc\s*\{\s*(\|[^\|]+\|)?\s*(.*?)\s*\}\Z/m, 2] || raise("Unable to parse proc's Ruby: #{to_ruby}")
  end
end

class Method
  def arguments
    (to_ruby[/\A(def [^\s\(]+)(?:\(([^\)]*)\))?/, 2] || '').split(/\s*,\s*/)
  end

  def to_ruby_without_method_declaration
    to_ruby[/\Adef [^\s\(]+(?:\([^\)]*\))?\s*(.*?)\s*end\Z/m, 1] || raise("Unable to parse method's Ruby: #{to_ruby}")
  end
end
