module ActionArgs
  #
  # Corresponds to an OptHashCfg.
  #
  class OptAccessor < Accessor

    # params:  { symbol => string }
    # :: hash, HashCfg -> Accessor
    def initialize(params, config)
      @params = params
      @config = config
      @errors = {}
      @args = @params ? compute_args : nil
    end

    # :: () -> bool
    def empty?
      @args.nil?
    end

    # For non-null sets.
    # :: () -> bool
    def provided?
      !empty?
    end

  end
end
