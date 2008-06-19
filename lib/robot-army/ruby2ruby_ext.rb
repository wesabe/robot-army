class Proc
  def arguments
    (to_ruby[/\Aproc \{ \|([^\|]+)\|/, 1] || '').split(/\s*,\s*/)
  end
  
  def to_ruby_with_body_flag(only_body=false)
    only_body ? to_method.to_ruby(true) : to_ruby_without_body_flag
  end
  
  alias :to_ruby_without_body_flag :to_ruby
  alias :to_ruby :to_ruby_with_body_flag
end

class Method
  def arguments
    (to_ruby[/\A(def [^\s\(]+)(?:\(([^\)]*)\))?/, 2] || '').split(/\s*,\s*/)
  end
  
  def to_ruby_with_body_flag(only_body=false)
    ruby = self.to_ruby_without_body_flag
    if only_body
      ruby.sub!(/\A(def [^\s\(]+)(?:\(([^\)]*)\))?/, '')   # move args
      ruby.sub!(/end\Z/, '')                          # strip end
    end
    ruby.gsub!(/\s+$/, '')                            # trailing WS bugs me
    ruby
  end
  
  alias :to_ruby_without_body_flag :to_ruby
  alias :to_ruby :to_ruby_with_body_flag
end
