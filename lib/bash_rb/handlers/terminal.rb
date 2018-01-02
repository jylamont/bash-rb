

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
        caller.push(
          DynamicCommand.interpret(method_name, *args)
        )
      end

      def exit_command
        "exit"
      end

      def is_exiting?(command)
        command.strip == exit_command
      end
    end
  end
end