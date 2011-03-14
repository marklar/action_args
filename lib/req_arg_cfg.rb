module ActionArgs

  class ReqArgCfg < ArgCfg

    # A ConfigError will have been thrown if not valid.
    def valid?
      true
    end

    # :: 'a -> raises
    def default(value)
      raise ConfigError, "Required arg #{@name.inspect} may not accept a default value."
    end

  end
end
