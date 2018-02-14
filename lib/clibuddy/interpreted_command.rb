require 'forwardable'

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
    end

    # Returns a mapping from required arg name to provided arg. Values will be nil if a required arg is not provided.
    def mapped_args
      a = {}
      # TODO this does not account for optional args which take an argument (EG, `--file /path`)
      # TODO parse the provided args against the command definition
      provided_required_args = @provided_args.reject { |a| a.start_with?("--") }
      cmd.definition.arguments.each_with_index do |arg, i|
        a[arg.name] = provided_required_args[i]
      end
      a
    end

    # Return any flow that matches the provided args or nil if none match
    def flow
      cmd.flow.find { |f| f.expression == provided_args.join(" ") }
    end

  end
end
