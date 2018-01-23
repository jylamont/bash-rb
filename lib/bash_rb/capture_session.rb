require_relative 'session'

module BashRb
  class CaptureSession < Session
    attr_reader :commands

    def initialize
      @handlers = [BashRb::Handlers::Terminal.new]
      @commands ||= []
    end

    def push(command)
      @commands << command
    end

    def repl(language, &block)
      get_repl_handler!(language)

      push(block.call(DynamicCommand.new))
  
      self
    end
  end
end