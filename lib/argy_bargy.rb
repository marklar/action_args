#
# "Pulling values from params, pulling values from params." - Squeeze
#
# Include this module in ApplicationController.
# Then, in your controllers, you may:
#   - add 'args_for :action_name' declarations, then
#   - use 'args' in your actions (in place of 'params')
#
module ActionController
  module ArgyBargy
    
    #
    # Create class variable in mixed-into class (ApplicationController).
    #   { ControllerClass =>
    #       { action_name => arg_config }
    #   }
    #
    # Class vars use lexical scoping --
    # in order to access the class var, use
    #     self.class_variable_{get|set}
    # from inside class methods.
    #
    def self.included(klass)
      class << klass
        @@args_cfg = {}
      end
      klass.extend(ClassMethods)
      klass.before_filter :access_args
    end
    
    module ClassMethods
      # Create the args config for a method.
      # Store in class-variable hash, for use by #access_args before_filter.
      # :: symbol, block -> unit
      def args_for(action_name_sym, opts={:raise_p => true}, &block)
        cfg = class_variable_get(:@@args_cfg)
        cfg[self] ||= {}
        cfg[self][action_name_sym.to_s] =
          ActionArgs::HashCfg.new(nil, opts[:raise_p], &block)
      end

      # Allow access to args config for a method.
      # :: string -> ActionArgs::HashCfg | nil
      def get_cfg(action_name_str)
        cfg = class_variable_get(:@@args_cfg)
        cfg[self] ? cfg[self][action_name_str] : nil
      end
    end

    # 1. Fetch args config (if any) for this method.
    # 2. Create an Accessor, which wrangles params:
    #     - checks for required ones
    #     - casts values (as required)
    #     - validates (as required)
    #     - munges (as required)
    # 3. Make Accessor available in instance var.
    # 4. Raise, if validation problems.
    #
    # :: -> unit.  (sets @args.)
    def access_args
      cfg = self.class.get_cfg(params[:action].to_s)
      if cfg
        @args = ActionArgs::Accessor.new(params, cfg)
        if !@args.valid? && @args.should_raise?
          errors_str = @args.errors.map do |name, exc|
            " #{name.inspect} :: #{exc}"
          end.join("\n")
          raise(ActionArgs::ArgumentError,
                'Invalid arguments supplied for action ' +
                "'#{params[:action].to_s}'.\n#{errors_str}")
        end
      end
    end

    # :: -> ActionArgs::Accessor
    def args;  @args  end
    
  end
end

