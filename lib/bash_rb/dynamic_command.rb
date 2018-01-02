class DynamicCommand
  def self.interpret(method_name, *args)
    new.interpret(method_name, *args)
  end

  def method_missing(method_name, *args)
    interpret(method_name, *args)
  end

  def interpret(method_name, *args)
    options = extract_options!(args)
    args.unshift(formatted_flags(options[:flags])) if options[:flags]
    "#{method_name} #{args.join(' ')}"
  end

  private

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