# TODO - ui elements to split out.
require "tty-spinner"

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

    def child_of_parallel?(action)
      action.parent && action.parent.directive == ".parallel"
    end

    def run_flow_actions(actions)
      return if actions.nil? || actions.empty?
      actions.each do |action|
        # TODO this gets weird for parallel spinners -
        # we have to register them all first, then
        # we can start autospin.  I'm tihnking
        # we'll just build jobs that consist of updates for them...
        maybe_delay(action.delay)
        name = action.directive.gsub(/^./, "").gsub(/-/, "_")
        self.send("do_#{name}".to_sym, action)
        run_flow_actions(action.children)
      end
    end

    def do_parallel(action)
      # TODO fail if we're a cild of a spinner?
      # For now, we just support multi-spiner for parallel
      action.ui = ::TTY::Spinner::Multi.new("[:spinner] :status")
      action.update(status: action.msg)
    end

    def do_spinner(action)
      if child_of_parallel? action
        action.ui = action.parent.ui.register("[:spinner] :status")
      else
        action.ui = ::TTY::Spinner::new("[:spinner] :status")
        # TODO - don't forget rendering and substitution in text...
        action.ui.update status: action.msg
        action.ui.auto_spin
      end

    end

    def do_show_text(action)
      if action.parent && action.parent.directive == ".spinner"
        action.parent.ui.update(status: action.msg)
      else
        puts action.msg
      end
    end

    def do_failure(action)
      if action.parent && action.parent.directive == ".spinner"
        action.parent.ui.update(status: "")
        action.parent.ui.error(action.msg)
      else
        puts action.msg
      end
    end

    def do_success(action)
      if action.parent && action.parent.directive == ".spinner"
        action.parent.ui.update(status: "")
        action.parent.ui.success(action.msg)
      else
        puts action.msg
      end
    end
    def do_show_error(action)
      err = lookup_message(action.args)
      # TODO formatting and substitution
      puts err.join("\n")
    end

    def do_show_usage()
      # TODO when user types `--help` then we show the full usage text plus usage string,
      # if they typo a command/used unrecognized arguments we show the short usage test plus usage string.
      puts @cmd.usage[:full]
    end

    def maybe_delay(delay_spec)
      return if delay_spec.nil?
      case delay_spec[:unit]
      when :ms
        sleep(1.0 / delay_spec[:value])
      when :s
        sleep(delay_spec[:value])
      end
    end

    def lookup_flow(expr)
      flow = @cmd.flow.find { |f| f.expression == expr }
      if flow.nil?
        raise "No flow defined for command [#{input_cmd}] args #{expr}"
      end
      flow
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
        "#{name} This message is not defined yet. Make sure you add it to the 'messages' section!"
      else
        msg.values
      end
    end
  end
end
