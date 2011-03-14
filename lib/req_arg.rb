module ActionArgs
  #
  # Required arg.
  # Will raise if no provided @str.
  #
  class ReqArg < Arg

    private

    def value_from_str
      calc_value
    end

    # :: -> raises
    def str_from_blank
      raise ArgumentError.new("Arg #{@cfg.name.inspect} is required but absent.")
    end

  end
end
  
