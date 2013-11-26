module ActionArgs

  # -- ABSTRACT --
  class ArgCfg
    
    SIMPLE_TYPES = [:bool,
                    :float,
                    :int, :positive_int, :unsigned_int,
                    :string, :symbol]
    # ARRAY_TYPES = SIMPLE_TYPES.map {|t| (t.to_s + '_array').to_sym }
    # ToDo: add support for :float_array.
    #   How to support string/symbol arrays?  What's the separator?
    ARRAY_TYPES = [:int_array, :positive_int_array, :unsigned_int_array,
                   :float_array]
    TYPE_NAMES = SIMPLE_TYPES + ARRAY_TYPES
    
    attr_reader :name, :type_name, :munger, :validator, :valid_values
    
    def initialize(param_name)
      unless param_name.is_a? Symbol
        raise ConfigError, "Argument name #{name.inspect} must be symbol."
      end
      @name = param_name
      @type_name = :string      # default: :string. override w/ #as.
      @munger    = ->(b) {b}    # default: :id.     override w/ #munge.
      @validator = ->(_) {true} # default: :no-op.  override w/ #validate.
    end

    # Takes a Symbol, the name of the argument type.
    # If it's among the valid argument types, set @type_name.
    # Else, raise.
    #
    # May raise.
    # :: Symbol -> ArgCfg (mutated)
    def as(type_name)
      case type_name
      when *TYPE_NAMES
        @type_name = type_name
      when Symbol
        s = type_name.inspect
        raise ConfigError, "Type name #{s} not among known types."
      else
        s = type_name.inspect
        raise ConfigError, "Type name #{s} must be a Symbol."
      end
      self
    end

    # Takes a pure function :: a -> a.  Any of:
    #   + symbol (method name)
    #   + proc/lambda
    #   + block
    #
    # This function should expect the value to be
    # already converted to its proper type.
    # It should normalize the value; e.g. to downcase strings.
    # It should maintain type.
    #
    # :: symbol|proc, block -> ArgCfg (mutated)
    def munge(sym_or_proc=nil, &block)
      @munger = get_proc(:munge, sym_or_proc, block)
      self
    end

    # Takes a pure function :: a -> bool.  Any of:
    #   + symbol (method name)
    #   + proc/lambda
    #   + block
    #
    # This function should expect the value to be
    # already converted to its proper type.
    #
    # :: symbol|proc, block -> ArgCfg (mutated)
    def validate(sym_or_proc=nil, &block)
      @validator = get_proc(:validate, sym_or_proc, block)
      self
    end

    # Takes an Array|Range or other object with responds_to #include?
    # 
    # The argument value will first be converted to its proper type
    # and then checked for membership in 'valid_values'.
    #
    # :: Array | Range -> ArgCfg (mutated)
    def validate_in(valid_values)
      @valid_values = get_valid_values(valid_values)
      self
    end
    
    #--------
    private

    # May raise.
    # :: (a implements #include?) => a -> a
    def get_valid_values(values)
      if values.respond_to?(:include?)
        values
      else
        raise ConfigError, '#validate_in takes only objects that ' +
          "respond to #include?.  Not this: #{values.inspect}"
      end
    end

    # May raise.
    # :: symbol, symbol|proc|nil, proc|nil -> proc
    def get_proc(method_name, sym_or_proc=nil, proc=nil)
      if sym_or_proc && proc
        raise ConfigError, "#{@name.inspect}'s ##{method_name} cannot take" +
          'both an argument and a block.'
      end
      proc = case sym_or_proc
             when nil
               proc
             when Proc
               sym_or_proc
             when Symbol
               sym_or_proc.to_proc
             else
               raise ConfigError, "#{@name.inspect}... ##{method_name} " +
                 'takes only a symbol, a proc, or a block.'
             end
      validate_unarity(proc, method_name)  # may raise
      proc
    end

    # Symbol#to_proc always creates a Proc with arity of -1
    # (i.e. number of args unknown).
    #
    # May raise.
    # :: proc, symbol -> unit | raise
    def validate_unarity(proc, method_name)
      if ![1, -1].include?(proc.arity)
        raise ConfigError, "Proc for #{@name.inspect}'s ##{method_name} has an " +
          "arity of #{proc.arity} when it should be 1."
      end
    end

  end
end
