# TODO - ui elements to split out.
require "tty-spinner"
require "clibuddy/formatters"
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
        maybe_delay(action)

        # invoke do_DIRECTIVE
        name = action.directive.gsub(/^./, "").gsub(/-/, "_")
        self.send("do_#{name}".to_sym, action)

        # invoke do_post_DIRECTIVE if it exists
        post_action = "do_post_#{name}".to_sym
        run_flow_actions(action.children)
        if respond_to? post_action
          self.send(post_action, action)
        end
      end
    end

    ######

    def do_parallel(action)
      # For now, we just support multi-spinner for parallel
      # Other options could include progress bar, or
      # plain text refreshed inline.
      action.ui = ::TTY::Spinner::Multi.new(":spinner #{action.msg}", format: :spin)
    end

    def do_post_parallel(action)
      # This 'post' function is called after child components are setup for
      # we'll invoke ui.auto_spin  here, which will start the spinners and execute their jobs -
      # which are just further calls into run_flow_actions
      action.ui.auto_spin
    end

    def do_spinner(action)
      if child_of_parallel? action
        action.ui = action.parent.ui.register(":spinner :status")
        action.ui.update status: action.msg
        # We're going to take the children of this spinner
        # so that we can run them async as a spinner job
        adoptees = action.children
        action.children = []
        action.ui.job do |_spinner|
          run_flow_actions(adoptees)
        end

      else
        action.ui = ::TTY::Spinner::new(":spinner :status")
        action.ui.update status: action.msg
        # TODO - don't forget rendering and substitution in text...
        action.ui.auto_spin
      end
    end

    def do_show_text(action)
      p_directive = action.parent ? action.parent.directive : nil
      case p_directive
      when ".spinner"
        action.parent.ui.update(status: action.msg)
      else
        puts action.msg
      end
    end

    def do_failure(action)
      p_directive = action.parent ? action.parent.directive : nil
      case p_directive
      when ".spinner"
        action.parent.ui.update(status: action.msg)
        action.parent.ui.error
      else
        # TODO - it'll make sense to create aa corresponding UI element so that we can just
        # blindly ui.update...
        action.ui = ::TTY::Spinner::new(":spinner #{action.msg}", format: :spin)
        action.ui.error
      end
    end

    def do_success(action)
      p_directive = action.parent ? action.parent.directive : nil
      case p_directive
      when ".spinner"
        action.parent.ui.update(status: action.msg)
        action.parent.ui.success
      else
        # Unspun spinners double as simple success/failure indicators
        action.ui = ::TTY::Spinner::new(":spinner #{action.msg}", format: :spin)
        action.ui.success
      end
    end

    def do_show_error(action)
      err = lookup_message(action.args)
      # TODO formatting and substitution
      puts err.join("\n")
    end

    def do_show_usage(action)
      usage = Formatters::CommandUsageFormatter.new(@cmd)
      puts usage.long_usage_text
      args_table = usage.long_usage_detail_table
      puts args_table.render(:basic, multiline: true, resize: true,
                             alignments: [:right, :left])

    end

    def maybe_delay(action)
      return if action.delay.nil?
      return if child_of_parallel?(action)
      delay_spec = action.delay
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
