# TODO - ui elements to split out.
require "tty-spinner"
require "tty-table"
require "clibuddy/formatters/output_formatter"
require "clibuddy/formatters/command_usage_formatter"
require "clibuddy/interpreted_command"
require "clibuddy/runner/errors"

module CLIBuddy
  class Runner
    attr_reader :parser, :cmd

    # The runner's job is to parse the user supplied args, match them against the parsed flow and then invoke any actions
    # accordingly
    def initialize(parser, input_cmd, input_cmd_args)
      # TODO parser now holds a builder, lets rename this
      @parser = parser
      @cmd = lookup_command(input_cmd, input_cmd_args)
    end

    def run
      # TODO somewhere we need to parse the input against the command definition. IE, this allows us to know that
      # the first arg provided to the command is `HOST` when referenced in the actions later
      flow = lookup_flow
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
      action.ui = ::TTY::Spinner::Multi.new(":spinner #{format(action.msg)}", format: :spin)
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
        action.ui.update status: format(action.msg)
        # We're going to take the children of this spinner
        # so that we can run them async as a spinner job
        adoptees = action.children
        action.children = []
        action.ui.job do |_spinner|
          run_flow_actions(adoptees)
        end

      else
        action.ui = ::TTY::Spinner::new(":spinner :status")
        action.ui.update status: format(action.msg)
        # TODO - don't forget rendering and substitution in text...
        action.ui.auto_spin
      end
    end

    def do_show_text(action)
      p_directive = action.parent ? action.parent.directive : nil
      case p_directive
      when ".spinner"
        action.parent.ui.update(status: format(action.msg))
      else
        puts format(action.msg)
      end
    end

    def do_failure(action)
      p_directive = action.parent ? action.parent.directive : nil
      case p_directive
      when ".spinner"
        action.parent.ui.update(status: format(action.msg))
        action.parent.ui.error
      else
        # TODO - it'll make sense to create aa corresponding UI element so that we can just
        # blindly ui.update...
        action.ui = ::TTY::Spinner::new(":spinner #{format(action.msg)}", format: :spin)
        action.ui.error
      end
    end

    def do_success(action)
      p_directive = action.parent ? action.parent.directive : nil
      case p_directive
      when ".spinner"
        action.parent.ui.update(status: format(action.msg))
        action.parent.ui.success
      else
        # Unspun spinners double as simple success/failure indicators
        action.ui = ::TTY::Spinner::new(":spinner #{format(action.msg)}", format: :spin)
        action.ui.success
      end
    end

    def do_show_error(action)
      puts format(lookup_message(action.args))
    end

    def do_show_usage(_action)
      usage = Formatters::CommandUsageFormatter.new(@cmd)
      puts usage.long_usage_text
      args = TTY::Table.new(usage.arguments)
      flags = TTY::Table.new(usage.flags)

      puts "Arguments:"
      puts args.render(:basic, multiline: true, resize: true,
                       alignments: [:right, :left],
                       column_widths: [0, 40])
      puts "\nFlags:"
      puts flags.render(:basic, multiline: true, resize: true,
                       alignments: [:right, :left],
                       column_widths: [0, 40])
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

    def lookup_command(name, provided_args)
      cmd = parser.lookup_command(name)
      if cmd.nil?
        # TODO how do we differentiate between runtime errors and flow "errors" that are supposed to happen
        # A: we can do differently-formatted exception handling that makes it clear.
        raise Errors::NoSuchCommand.new(name)
      end
      begin
        InterpretedCommand.new(cmd, provided_args)
      rescue OptionParser::ParseError => e
        puts "Could not parse the arguments provided to '#{cmd.name}': #{e.message}"
        exit 1
      end
    end

    def lookup_flow
      flow = cmd.flow
      if flow.nil?
        if cmd.provided_args.join(" ") == ""
          do_show_usage(nil)
          exit 1
        else
          raise Errors::NoMatchingFlow.new(cmd.name, cmd.provided_args)
        end
      end
      flow
    end

    def lookup_message(name)
      msg = parser.messages.find { |m| m.id == name }
      if msg.nil?
        "The message '#{name}' is not defined yet. Make sure you add it to the 'messages' section!"
      else
        msg.lines
      end
    end

    def format(msg)
      Formatters::OutputFormatter.format(msg, cmd.mapped_args)
    end
  end
end
