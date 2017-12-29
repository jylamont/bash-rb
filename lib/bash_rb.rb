require 'json'

module BashRb
  class ServiceNotFound < StandardError
  end

  class Session
    attr_reader :process, :handlers, :response
  
    SLEEP_TIME = 0.2
  
    def self.services 
      @@services ||= {}
    end

    def self.define_service(hash)
      @@services ||= {}
      @@services = Hash.new(@@services).merge(hash)
    end
  
    def self.get_service(service_name)
      return nil unless service_name.is_a?(String) || service_name.is_a?(Symbol)
      # (@@services || {})[service_name.to_sym]
    end
  
    def self.define_repl(hash)
      @@repl_languages ||= {}
      @@repl_languages = Hash.new(@@repl_languages).merge(hash)
    end
  
    def self.repl_languages
      if defined?(@@repl_languages)
        @@repl_languages
      else
        {}
      end
    end
  
    def initialize
      @response = {}
      @handlers = [TerminalHandler.new]

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
        @handlers.pop
        @current_handler = nil
        push_command(command)
        nil
      else
        command_digest = push_command(command)
        wait_for_command_output(command_digest)
        @response.delete(command_digest)
      end
    end
  
    def repl(command, options = {})
      repl_handler = BashRb::Session.repl_languages[options[:language]]
      raise NotImplementedError.new("Language: #{options[:language]} not implemented") unless repl_handler.is_a?(Hash) && repl_handler[:handler]
  
      @handlers << repl_handler[:handler].new
      @current_handler = nil
  
      process.puts(command)
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
  
    def push_command(command)
      Digest::MD5.hexdigest(command).tap do |command_digest|
        process.puts(current_handler.prepare_input(command))
        sleep(SLEEP_TIME)
        process.puts(current_handler.command_delimiter(command_digest))
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
  end

  class TerminalHandler
    def regex
      @regex ||= /^bashrb\:session\:finish => (.+)$/
    end
  
    def command_delimiter(command_digest)
      "echo 'bashrb:session:finish => #{command_digest}'"
    end
  
    def prepare_input(str)
      str
    end
  
    def prepare_output(lines)
      lines
    end
  
    def handle_method_missing(caller, method_name, *args)
      options = extract_options!(args)
  
      if service_command = extract_service_command(options[:service], method_name)
        service_command.call(caller, options)
      elsif options[:service]
        raise BashRb::ServiceNotFound.new(["service: #{options[:service]}", method_name])
      else
        args.unshift(formatted_flags(options[:flags])) if options[:flags]
        caller.push("#{method_name} #{args.join(' ')}")
      end
    end
  
    def exit_command
      "exit"
    end
  
    def is_exiting?(command)
      command.strip == exit_command
    end
  
    def extract_options!(args)
      if args.last.is_a?(Hash)
        args.pop
      else
        {}
      end
    end
  
    def formatted_flags(flags)
      if flags.is_a?(Hash)
        flags.map { |f,v| "-#{f} #{v.to_s}".strip }.join(' ')
      else
        flags
      end
    end
  
    def extract_service_command(service, method)
      if service_commands = BashRb::Session.get_service(service)
        service_commands[method.to_sym]
      end
    end
  end
  
  class RubyHandler < TerminalHandler
    def regex
      @regex ||= /^"bashrb\:ruby\:finish => (.+)"$/
    end
  
    def command_delimiter(command_digest)
      %("bashrb:ruby:finish => #{command_digest}")
    end
  
    def prepare_input(str)
      code = <<-EOM
        require 'json'
        result = begin
        #{str}
        end
        JSON.dump([result])
      EOM
    end
  
    def prepare_output(lines)
      text = sanitize(lines.pop.to_s)
      JSON.parse(text).first
    rescue
      nil
    end
  
    def handle_method_missing(caller, method_name, *args)
      caller.push "#{method_name}(#{args.to_s[1...-1]})"
    end
  
    def sanitize(text)
      text.gsub!("\\\"", "\"")
      text = text[1...-1] # Remove quotes from SSH string
    end
  end
end