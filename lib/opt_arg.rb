module ActionArgs
  #
  # Optional arg.  (If str is nil, then try default.)
  #
  class OptArg < Arg

    private

    def value_from_str
      @str.nil? ? @cfg.default_value : calc_value
    end

    def str_from_blank
      nil
    end

  end
end
  
