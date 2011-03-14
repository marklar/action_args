module ActionArgs
  #
  # Takes:
  #   - params hash
  #   - config for those params
  #
  # Each param can be either a "simple" value,
  # or it can be a Hash.
  # For each, create an 'arg', whose type depends on
  # whether the param is simple or a hash:
  #   - Hash   -> Accessor  (optional or regular)
  #   - simple -> Arg       (optional or required)
  #
  class Accessor

    attr_reader :errors

    # params:  { symbol => string }
    # :: Hash, HashCfg -> Accessor
    def initialize(params, config)
      @params = params
      @config = config
      @errors = {}
      @args = compute_args
      validate_non_null_sets
    end

    def should_raise?;  @config.raise_p  end
    def valid?;         @errors.empty?   end
    def empty?;         false            end

    # :: symbol -> Arg | Accessor | nil
    def [](arg_name_sym)
      case a = @args[arg_name_sym]
      when nil
        raise(ArgumentError,
              "Typo?  There is no arg #{arg_name_sym.inspect}.")
      when Arg      # either Opt or Req
        a.value
      when Accessor # either Opt or regular
        a.empty? ? nil : a
      else
        raise RuntimeError, "Shouldn't get here."
      end
    end

    #--------
    private

    # Looks at all (should-be) non-null sets,
    # and if it finds that any *are* null, adds to @errors.
    #
    # :: () -> ()
    def validate_non_null_sets
      @config.non_null_sets.each_with_index do |set, idx|
        unless set.any? {|name| @args[name].provided? }
          add_error("non_null_set_#{idx}".to_sym,
                    "Must provide at least one of: #{set.inspect}")
        end
      end
    end

    # Create an Arg (or Accessor, for Hashes)
    # for each config declaration.
    #
    # MAY RAISE, if:
    #   - required param is absent
    #   - param value doesn't validate
    # Gather exceptions in @errors.
    #
    # :: () -> { symbol => [Opt]Arg | [Opt]Accessor }
    def compute_args
      # cfg could be for either:
      #   - Arg : for "simple" arguments
      #   - Accessor : for hashes
      @config.inject({}) do |memo, cfg|
        klass = case cfg
                  # Order matters here...
                when OptHashCfg then OptAccessor
                when HashCfg    then Accessor
                  # ...and here.
                when OptArgCfg  then OptArg
                when ArgCfg     then ReqArg
                else
                  raise ConfigError, 'Should not get here.'
                end
        begin
          memo[cfg.name] = klass.new(@params[cfg.name], cfg)
        rescue Exception => e
          memo[cfg.name] = nil
          @errors[cfg.name] = e
        end
        memo
      end
    end

    # :: (Symbol, String) -> ()
    def add_error(name, error_str)
      @errors[name] = error_str
    end

  end
end
