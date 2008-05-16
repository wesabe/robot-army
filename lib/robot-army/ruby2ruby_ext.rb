class Proc
  def to_ruby_with_body_flag(only_body=false)
    ruby = to_ruby_without_body_flag
    only_body ? "#{ruby}.call" : ruby
  end
  
  alias :to_ruby_without_body_flag :to_ruby
  alias :to_ruby :to_ruby_with_body_flag
end

class Method
  def to_ruby_with_body_flag(only_body=false)
    ruby = self.to_ruby_without_body_flag
    if only_body
      ruby.sub!(/\A(def \S+)(?:\(([^\)]*)\))?/, '')   # move args
      ruby.sub!(/end\Z/, '')                          # strip end
    end
    ruby.gsub!(/\s+$/, '')                            # trailing WS bugs me
    ruby
  end
  
  alias :to_ruby_without_body_flag :to_ruby
  alias :to_ruby :to_ruby_with_body_flag
end
