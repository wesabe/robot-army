require 'thor'

module RobotArmy
  class TaskMaster < Thor
    def self.host(host=nil)
      @host = host if host
      @host
    end
  
    def host
      self.class.host
    end
  
    def say(something)
      puts "** #{something}"
    end
  
    def remote(host=self.host, &proc)
      require 'ruby2ruby'
      require 'open3'
    
      # fix stack traces
      file, lineno = eval('[__FILE__, __LINE__]', proc.binding)
    
      # include local variables
      locals = eval('local_variables', proc.binding).map do |name|
        "#{name} = Marshal.load(#{Marshal.dump(eval(name, proc.binding)).inspect})"
      end
    
      # if we're given a host, use that, otherwise just use this machine
      cmd = host ? "ssh #{host} ruby" : "ruby"
    
      stdin, stdout, stderr = Open3.popen3 cmd
      stdin.puts <<-RUBY
      begin
        require 'tempfile'
      
        def sh(*parts)
          cmd = parts.join(' ')
          system cmd
        end
      
        #{locals.join("\n")}
      
        print Marshal.dump({
          :status => 'ok', 
          :data => instance_eval(#{"#{proc.to_ruby}.call".inspect}, #{file.inspect}, #{lineno.inspect})
        })
      rescue Object => e
        print Marshal.dump({
          :status => 'error', 
          :data => e
        })
      end
      RUBY
      stdin.close
      $stderr.print stderr.read
      data = stdout.read
    
      response = Marshal.load(data)
      data = response[:data]
    
      case response[:status]
      when 'ok'
        return data
      when 'error'
        raise data
      else
        raise RuntimeError, "Unknown response status from remote process: #{response[:status]}"
      end
    end
  
    def self.mock
      new(:noop, {})
    end
  
    private
  
    def noop
      # this only exists so that we can call something that'll do nothing
    end
  end
end
