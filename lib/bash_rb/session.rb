module BashRb
  class Session
    attr_reader :process, :handlers, :response
  
    SLEEP_TIME = 0.2
  
    def self.define_repl(hash)
      new_hash = hash.each_with_object({}) do |(k,v), h|
        h[k.to_s] = v
      end
      @@repl_languages = repl_languages.merge(new_hash)
    end
  
    def self.repl_languages
      @@repl_languages ||= {}
    end

    def self.reset_repl_languages
      @@repl_languages = {}
    end
  
    def initialize
      @response = {}
      @handlers = [BashRb::Handlers::Terminal.new]

      @process = IO.popen("bash", "w+")
      Thread.new { handle_process_output }
    end
  
    def close
      push(current_handler.exit_command) until @handlers.empty?
    rescue
    ensure
      kill_process(@process.pid)
    end
  
    def current_handler
      @current_handler ||= @handlers.last
    end
  
    def push(command)
      raise "Terminal closed. You will need to create a new BashRb::Session." if @handlers.empty?
  
      if current_handler.is_exiting?(command)
        push_command(command, with_curr_handler: false)
        
        sleep(SLEEP_TIME)

        @response.clear
        @handlers.pop
        @current_handler = nil
      else
        command_digest = push_command(command)
        wait_for_command_output(command_digest)
        @response.delete(command_digest)
      end
    end
  
    def repl(language, &block)
      @handlers << get_repl_handler!(language)
      @current_handler = nil
  
      process.puts(block.call(DynamicCommand.new))
      process.puts(current_handler.command_delimiter("blank"))
  
      self
    end
  
    def method_missing(method_name, *args)
      current_handler.handle_method_missing(self, method_name, *args)
    end
  
    private
  
    def handle_process_output
      lines = []
  
      @process.each_line do |l|
        l = l.strip
  
        if l =~ current_handler.regex
          @response[$1] = current_handler.prepare_output(lines) unless @response[$1]
          lines = []
        else
          lines << l.strip
        end
      end
    end
  
    def push_command(command, with_curr_handler: true)
      Digest::MD5.hexdigest(command).tap do |command_digest|
        handler = with_curr_handler ? current_handler : @handlers.first
        process.puts handler.prepare_input(command)
        process.puts handler.command_delimiter(command_digest)
      end
    end
  
    def wait_for_command_output(command_digest)
      loop do
        break if @response.has_key?(command_digest)
        sleep(SLEEP_TIME)
      end
    end
  
    def kill_process(pid)
      Process.getpgid(pid)
      Process.kill("TERM", pid)
      Process.wait
      true
    rescue
      false
    end

    def get_repl_handler!(language)
      repl_handler = BashRb::Session.repl_languages[language.to_s]
      
      unless repl_handler
        raise NotImplementedError.new("Language: #{language} not implemented") 
      end

      repl_handler.new
    end
  end
end