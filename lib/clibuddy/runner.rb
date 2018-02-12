module CLIBuddy
  class Runner
    attr_reader :parser, :input_cmd, :input_cmd_args

    # The runner's job is to parse the user supplied args, match them against the parsed flow and then invoke any actions
    # accordingly
    def initialize(parser, input_cmd, input_cmd_args)
      @parser = parser
      @input_cmd = input_cmd
      @input_cmd_args = input_cmd_args
    end

    def run
      cmd = parser.commands.find { |c| c.name == input_cmd }
      if cmd.nil?
        # TODO how do we differentiate between runtime errors and flow "errors" that are supposed to happen
        raise "No command matches [#{input_cmd}]"
      end

      # TODO somewhere we need to parse the input against the command definition. IE, this allows us to know that
      # the first arg provided to the command is `HOST` when referenced in the actions later

      flow = cmd.flow.find { |f| f.expression == input_cmd_args.join(" ") }
      if flow.nil?
        raise "No flow defined for command [#{input_cmd}] args [#{input_cmd_args}]"
      end

      flow.actions.each do |action|
        case action.directive
        when ".show-error"
          err = lookup_message(action.args)
          if err.nil?
            raise "No message defined for name [#{action.args}]"
          end
          # TODO where do we do message formatting
          puts err.lines.join("\n")
        when ".show-usage"
          # TODO when user types `--help` then we show the full usage text, if they typo a command we show the short
          # usage test
          puts cmd.usage[:full]
        end
      end
    end

    def lookup_message(name)
      parser.messages.find { |m| m.id == name }
    end

  end
end
