module ActionArgs

  class ReqArgCfg < ArgCfg

    # A ConfigError will have been thrown if not valid.
    def valid?
      true
    end

    # Because this is a Required parameter,
    # attempting to provide it with a default value makes no sense.
    # Raises ConfigError.
    # 
    # :: a -> raises
    def default(value)
      n = @name.inspect
      raise ConfigError, "Required arg #{n} may not accept a default value."
    end

  end
end
