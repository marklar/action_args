module ActionArgs

  # ABSTRACT.
  class Arg

    attr_accessor :value

    FALSE_STRS = 'f', 'false', '0'
    # Is this a good idea?
    TRUE_STRS  = 't', 'true',  '1'
    BOOL_STRS  = FALSE_STRS + TRUE_STRS

    # :: string|nil, ArgCfg -> Arg
    # str: the value passed in for this parameter
    # cfg: the user-provided rules (type, munging, validationg) for this argument
    def initialize(str, cfg)
      @cfg = cfg
      @str = str_from_input(str)  # may raise
      @value = value_from_str
      validate
    end

    # :: () -> bool
    # True if a non-nil value was provided for this parameter.
    def provided?
      !@str.nil?
    end

    # :: () -> bool
    # If a value was supplied for this parameter, return true if it passes
    # all validation:
    #   - is in range for type
    #   - is among explicitly specified options
    #   - passes validator function
    def valid?
      if !value.nil?
        in_range_for_type? &&
          among_validate_in_values? &&
          @cfg.validator.call(value)
      else
        true
      end
    end

    #--------
    private

    # :: () -> bool
    def among_validate_in_values?
      vs = @cfg.valid_values
      !vs || vs.include?(@value)
    end

    # NOT DRY.  Same as in opt_arg_cfg.rb.
    # :: () -> bool
    def in_range_for_type?
      case @cfg.type_name
      when :positive_int
        value >  0
      when :unsigned_int
        value >= 0
      when :positive_int_array
        value.all? {|i| i  > 0 }
      when :unsigned_int_array
        value.all? {|i| i >= 0 }
      else
        true
      end
    end

    # :: string -> nil | string | raises
    def str_from_input(str)
      case str
      when nil
        str_from_blank   # defined in concrete subclass
      when String
        x = str.strip
        x == '' ? str_from_blank : x
      else
        raise not_string_exc(str)
      end
    end

    # :: () -> unit | raises
    def validate
      unless valid?
        n = @cfg.name.inspect
        v = @value.inspect
        raise(ArgumentError, "Arg #{n}'s value (#{v}) does not validate.")
      end
    end

    # :: () -> valid-type | raises
    def calc_value
      @cfg.munger.call(to_type)
    end

    # :: () -> valid-type | exc
    # Takes (implicitly) the input String (@str) and returns a new value
    # by converting it to the proper type (e.g. Bool, Int, Float, Symbol).
    def to_type
      case @cfg.type_name
      when :bool
        bool_from_str(@str.downcase)
      when :int, :positive_int, :unsigned_int
        raise exc unless valid_int_str?(cleaned_num_str)
        cleaned_num_str.to_i
      when :float
        raise exc unless valid_float_str?(cleaned_num_str)
        cleaned_num_str.to_f
      when :string
        @str
      when :symbol
        @str.to_sym
      when :int_array, :positive_int_array, :unsigned_int_array
        ints_from_csv_str
        # add more _array types!
      when :float_array
        floats_from_csv_str
      else
        raise ConfigError, "Type not yet supported: #{@cfg.type_name}."
      end
    end
    
    # :: () -> ArgumentError
    def exc
      ArgumentError.new("Arg value #{@str} isn't a valid #{@cfg.type_name}.")
    end

=begin
    # :: () -> [float] | raises
    def floats_from_csv_str
      float_strs = @str.gsub(' ', '').split(',')
      unless float_strs.all? {|s| valid_float_str?(s) }
        raise ArgumentError, "Arg value #{@s} doesn't contain only valid floats."
      end
      float_strs.map {|s| s.to_f }
    end

    # :: () -> [int] | raises
    def ints_from_csv_str
      int_strs = @str.gsub(' ', '').split(',')
      unless int_strs.all? {|s| valid_int_str?(s) }
        raise ArgumentError, "Arg value #{@s} doesn't contain only valid ints."
      end
      int_strs.map {|s| s.to_i }
    end
=end

    # :: () -> [float] | raises
    def floats_from_csv_str
      nums_from_csv_str(:valid_float_str?, :to_f)
    end

    # :: () -> [int] | raises
    def ints_from_csv_str
      nums_from_csv_str(:valid_int_str?, :to_i)
    end

    def nums_from_csv_str(validate, converter)
      num_strs = @str.gsub(' ', '').split(',')
      unless num_strs.all? {|s| send(validate, s) }
        raise ArgumentError,
          "In arg value #{@str}, not all members are of valid type."
      end
      num_strs.map {|s| s.send(converter) }
    end
    
    # :: string -> bool
    def valid_int_str?(str)
      str =~ /^[+\-]?[\d]*$/     # optional sign, then only digits
    end
    
    # :: string -> bool
    def valid_float_str?(str)
      str =~ /^[+\-]?[\d\.]*$/   # optional sign, then only digits OR '.'
    end

    # Really not necessary to memoize this value,
    # as it only ever gets called once per instance.
    #
    # :: () -> string
    def cleaned_num_str
      @cleaned_num_str ||= sans_whitespace_and_commas
    end
    
    # String#to_i and #to_f stop parsing when they sees a space
    # (after the first digit).
    # Does not support the use of '.' as a 1000s-separator.
    #
    # :: () -> string
    def sans_whitespace_and_commas
      @str.gsub(' ', '').gsub(',', '')
    end

    # Create an ArgumentError (exception) object,
    # based on the argument's configuration and the provided value.
    #
    # :: string -> exc  (doesn't raise)
    def not_string_exc(str)
      n = @cfg.name.inspect
      v = str.inspect
      ArgumentError.new("Arg #{n}'s value must be a String: #{v}.")
    end

    # May raise.
    # :: string -> bool
    def bool_from_str(s)
      raise exc unless valid_bool_str?(s)
      case s
      when *FALSE_STRS
        false
      else
        true
      end
    end

    # :: () -> bool
    def valid_bool_str?(str)
      BOOL_STRS.include?(str)
    end
    
  end

end
