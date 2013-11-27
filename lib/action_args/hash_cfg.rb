module ActionArgs
  #
  # Config for all args for a single Controller action.
  # Instance created by #args_for declaration.
  #
  # Also, ABSTRACT base class for
  # config for a single hash-like argument,
  # either required (ReqHashCfg) or optional (OptHashCfg).
  # Those classes override NOTHING;
  # We simply branch behavior based on their classes.
  #
  class HashCfg
    include Enumerable

    attr_reader :name, :raise_p, :non_null_sets
    
    def initialize(name='top_level', raise_p=true, &block)
      @cfgs = {}
      @name = name
      @raise_p = raise_p
      @non_null_sets = []   # for #at_least_one_of
      @set = nil            #  "        "
      instance_eval &block
      valid?
    end

    # :: () -> true | exc
    def valid?
      @cfgs.each do |name, arg_cfg|
        unless arg_cfg.valid?
          raise(ConfigError,
                "Arg #{name.inspect}'s configuration does not validate.")
        end
      end
      true
    end
    
    ## :: Symbol -> Argument
    def [](name)
      @cfgs[name]
    end

    # :: opt block -> ()
    def each  # &block
      @cfgs.each {|_, cfg| yield cfg }
    end

    # :: Symbol -> ()
    def req(name)
      add_arg(name, ReqArgCfg)
    end
    
    # :: Symbol -> ()
    def opt(name)
      add_arg(name, OptArgCfg)
    end

    # :: (Symbol, Block) -> ()
    def req_hash(name, &block)
      add_arg(name, ReqHashCfg, &block)
    end

    # :: (Symbol, Block) -> ()
    def opt_hash(name, &block)
      add_arg(name, OptHashCfg, &block)
    end

    # :: opt block -> ()
    def at_least_one_of(&block)
      open_set
      instance_eval &block
      close_set
    end
    alias :at_least_1_of :at_least_one_of

    #--------
    private

    # :: () -> ()
    def open_set
      @set = []
    end

    # :: () -> ()
    def close_set
      if @set.empty?
        raise ConfigError, 'at_least_one_of block is empty!'
      end
      @non_null_sets << @set
      @set = nil
    end

    # match Block with
    #   | nil -> "simple" Arg
    #   | _   -> Hash Arg
    #
    # :: (Symbol, Class, Block|nil) -> ()
    def add_arg(name, klass, &block)
      if @cfgs[name]
        raise ConfigError, "Arg #{name.inspect} specified more than once."
      else
        add_to_non_null_set(name, klass) if inside_at_least_one_of?
        @cfgs[name] = klass.new(name, &block)
      end
    end

    # :: () -> Bool
    def inside_at_least_one_of?
      !@set.nil?
    end

    # :: (Symbol, Class) -> ()
    def add_to_non_null_set(name, klass)
      case klass.name
      when 'ActionArgs::OptArgCfg', 'ActionArgs::OptHashCfg'
        @set << name
      when 'ActionArgs::ReqArgCfg', 'ActionArgs::ReqHashCfg'
        raise(ConfigError, "Inside 'at_least_one_of' block, " +
              "only 'opt' and 'opt_hash' are allowed.")
      else
        # If we get here, we've probably extended the set
        # of Arg types without updating this method's logic.
        # (ML's pattern-matching exhaustiveness would help here.)
        raise(ConfigError, "What class is this?: #{klass.name}")
      end
    end

  end
end
