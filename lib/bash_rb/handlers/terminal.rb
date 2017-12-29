module BashRb
  module Handlers
    class Terminal
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

        args.unshift(formatted_flags(options[:flags])) if options[:flags]
        caller.push("#{method_name} #{args.join(' ')}")
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
    end
  end
end