require_relative 'terminal'

module BashRb
  module Handlers
    class Ruby < BashRb::Handlers::Terminal
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
end