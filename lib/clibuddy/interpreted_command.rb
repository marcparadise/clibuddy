require 'forwardable'
require 'optparse'

module CLIBuddy
  class InterpretedCommand
    extend Forwardable

    attr_reader :cmd, :provided_args

    def_delegators :@cmd, :usage, :definition, :arguments, :name

    # This class holds a command parsed from the CLI definition as well as the args passed to it during usage.
    # Allows us to determine what required and optional args were provided.
    def initialize(cmd, provided_args)
      @cmd = cmd
      @provided_args = provided_args
      validate_args
    end

    # Returns a mapping from required arg name to provided arg. Values will be nil if a required arg is not provided.
    def mapped_args
      return @mapped_args if @mapped_args
      @mapped_args = {}
      cmd.definition.arguments.each_with_index do |arg, i|
        mapped_args[arg.name] = @leftover_args[i]
      end
      # Allow output to reference the name of the main
      # command as CMD, which makes less work when
      # we decide to change a command.
      @mapped_args["CMD"] = cmd.name
      @mapped_args
      # TODO handle unexpected arguments, mapping them
      # such as EXTRA1, EXTRA2, etc.
    end

    # Return any flow that matches the provided args or nil if none match
    def flow
      cmd.flow.find { |f| args_match_flow? f }
    end

    private
    def args_match_flow?(flow)
      flow_args = flow.expression.split
      if flow_args.length > @leftover_args.length
        return false
      end
      @leftover_args.each_with_index do |arg, x|
        # TODO - easy to extend this to simplified pattern
        #        matching
        next if flow_args[x] == "*"
        next if arg == flow_args[x]
        return false

      end
      true
    end


    # All we care about doing is parsing the provided args against the command definition. If there are any
    # missing required args we should output some kind of standard 'arguments missing' error to the user.
    # The same is true of any other option parsing errors, like not suppling an arg to an option that requires
    # one. If there are no validation errors this has properly mapped provided args to options so they can be
    # easily returned from #mapped_args later
    def validate_args
      opt_parser = OptionParser.new do |opts|
        cmd.definition.flags.each do |flag|
          parser_args = []
          l = "--#{flag.flag}"
          if flag.arg
            if flag.arg =~ /^\[(.+)+\]$/
              # if the arg is optional (surrounded by []) then the long form must look like `--key[=VALUE]` while
              # the short form must look like `-k[VALUE]`
              l += "[=#{$1}]"
            else
              l += " #{flag.arg.upcase}" unless flag.arg.nil?
            end
          end
          parser_args << l
          if flag.short
            s = "-#{flag.short}"
            s += "#{flag.arg.upcase}" unless flag.arg.nil?
            parser_args << s
          end
          opts.on(*parser_args)
        end
      end
      # parse! destructively removes args and we want to see what non-option args were passed to use in
      # mapped_args later
      @leftover_args = provided_args.dup
      opt_parser.parse!(@leftover_args)
    end
  end
end
