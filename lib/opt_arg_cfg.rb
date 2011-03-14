module ActionArgs

  # Configuration for a single 'optional' arg.
  class OptArgCfg < ArgCfg
    
    attr_reader :default_value

    # :: ?? -> OptArgCfg (mutated)
    def default(value)
      if value.nil?
        raise ConfigError, "Default value for arg #{@name.inspect} cannot be nil."
      end
      @default_value = value
      self
    end

    # To be called by Config::Accessor
    # :: -> bool
    def valid?
      if @default_value
        value_of_default_ok? && type_of_default_ok?
      else
        true
      end
    end
    
    #--------
    private

    # :: -> bool
    def type_of_default_ok?
      case @type_name
      when *SIMPLE_TYPES
        of_proper_simple_type?(@default_value, @type_name)
      else
        if @default_value.is_a? Array
          of_proper_ary_type?(@default_value, @type_name)
        else
          raise ConfigError, "Default value for #{@name.inspect} was "+
            "expected to be an Array, but was: #{@default_value.inspect}."
        end
      end
    end

    # :: ('a, symbol) -> bool
    def of_proper_simple_type?(expr, type_name)
      proper_class?(expr, type_name) && in_range?(expr, type_name)
    end

    # :: ('a, symbol) -> bool
    def proper_class?(expr, type_name)
      ok_simple_classes(type_name).any? {|k| expr.is_a? k }
    end

    # :: symbol -> [Class]
    def ok_simple_classes(type_name)
      case type_name
      when :bool         then [FalseClass, TrueClass]
      when :float        then [Float, Fixnum]
      when :int          then [Fixnum]
      when :positive_int then [Fixnum]
      when :unsigned_int then [Fixnum]
      when :string       then [String]
      when :symbol       then [Symbol]
      else
        raise "Shouldn't get here."
      end
    end

    # ..for simple type..
    # :: 'a, symbol -> bool
    def in_range?(expr, type_name)
      case type_name
      when :positive_int then expr >  0
      when :unsigned_int then expr >= 0
      else
        true
      end
    end

    # :: ['a], symbol -> bool
    def of_proper_ary_type?(ary, ary_type_name)
      member_type_name = simple_type_name_from_ary_type_name(ary_type_name)
      ary.all? do |x|
        of_proper_simple_type?(x, member_type_name)
      end
    end

    # :: symbol -> symbol
    def simple_type_name_from_ary_type_name(ary_type_name)
      ary_type_name.to_s.sub(/_array$/, '').to_sym
    end

    # :: () -> bool
    def value_of_default_ok?
      default_validates? && default_in_valid_values?
    end

    # :: () -> bool
    def default_validates?
      if @validator
        begin
          @validator.call(@default_value)
        rescue ArgumentError => e
          raise ConfigError, "Arg #{@name.inspect}'s :validate expression " +
            "raised exception: #{e.inspect}."
        end
      else
        true
      end
    end
    
    # :: () -> bool
    def default_in_valid_values?
      if @valid_values
        @valid_values.include?(@default_value)
      else
        true
      end
    end

  end
end
