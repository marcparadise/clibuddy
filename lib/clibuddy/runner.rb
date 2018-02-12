module CLIBuddy
  class Runner
    attr_reader :parser, :input_cmd, :input_cmd_args, :cmd

    # The runner's job is to parse the user supplied args, match them against the parsed flow and then invoke any actions
    # accordingly
    def initialize(parser, input_cmd, input_cmd_args)
      @parser = parser
      @input_cmd = input_cmd
      @input_cmd_args = input_cmd_args
      @cmd = lookup_command(input_cmd)
    end

    def run
      # TODO somewhere we need to parse the input against the command definition. IE, this allows us to know that
      # the first arg provided to the command is `HOST` when referenced in the actions later
      flow = lookup_flow(input_cmd_args.join(" "))
      run_flow_actions(flow.actions)
    end

    def run_flow_actions(actions)
      actions.each do |action|
        if action.delay != nil
          do_delay(action.delay)
        end

        case action.directive
        when ".show-error"
          err = lookup_message(action.args)
          if err.nil?
            raise "No message defined for name [#{action.args}]"
          end
          # TODO where do we do message formatting
          puts err.lines.join("\n")
        when ".show-usage"
          # TODO when user types `--help` then we show the full usage text plus usage string,
          # if they typo a command/used unrecognized arguments we show the short usage test plus usage string.
          puts cmd.usage[:full]
        end
      end
      if action.children.length > 0
        run_flow_actions(action.children)
      end
    end

    def do_delay(delay_spec)
      case delay_spec[:unit]
        when :ms
          sleep(1.0 / delay_spec[:value])
        when :s
          sleep(delay_spec[:value])
        end
    end

    def lookup_flow(expr)
      flow = cmd.flow.find { |f| f.expression == expr }
      if flow.nil?
        raise "No flow defined for command [#{input_cmd}] args #{expr}"
      end
    end

    def lookup_command(name)
      cmd = parser.commands.find { |c| c.name == input_cmd }
      if cmd.nil?
        # TODO how do we differentiate between runtime errors and flow "errors" that are supposed to happen
        raise "No command matches [#{input_cmd}]"
      end
      cmd
    end

    def lookup_message(name)
      msg = parser.messages.find { |m| m.id == name }
      if msg.nil?
        "#{name} This message is not defined yet."
      else
        msg
      end
    end

  end
end
