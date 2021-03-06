# TODO - ui elements to split out.
require "tty-spinner"
require "tty-screen"
require "tty-table"
require "pastel"
require "clibuddy/formatters/output_formatter"
require "clibuddy/formatters/command_usage_formatter"
require "clibuddy/interpreted_command"
require "clibuddy/runner/errors"

module CLIBuddy
  class Runner
    attr_reader :parser, :cmd

    # The runner's job is to parse the user supplied args, match them against the parsed flow and then invoke any actions
    # accordingly
    def initialize(parser, input_cmd, input_cmd_args, opts = { } )
      # TODO parser now holds a builder, lets rename this
      @parser = parser
      @opts = opts
      @cmd_name = input_cmd
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

    def do_wait_for_key(action)
      require 'tty/prompt'
      @prompt = TTY::Prompt.new(interrupt: :exit)
      @prompt.keypress(format(action.msg))
    # TODO rescue Interrupt
    end

    def do_description(action)
      # Metadata, no action
    end

    def do_parallel(action)
      # For now, we just support multi-spinner for parallel operations
      # Other options could include progress bar, or plain text refreshed inline.
      action.ui = ::TTY::Spinner::Multi.new(":spinner #{format(action.msg)}", format: :spin)
    end

    def do_post_parallel(action)
      # This 'post' function is called after child components are setup
      # we'll invoke ui.auto_spin  here, which will start the spinners and execute their jobs -
      # which are just further calls into run_flow_actions
      action.ui.auto_spin
    end

    def do_use(action)
      # Replace wildcards in the action spec with the provided command args
      # so that they continue to work in the sub-flow run
      # TODO - ideally this will let the user specify the name of the argument,
      # and that will be translated as we do for
      x = 0;
      max = @cmd.provided_args.length
      while (x < max)
        proposed = @cmd.mapped_args[action.args[x]]
        # use the already-mapped named value if we got a named arg
        action.args[x] = proposed  if proposed && action.args[x] =~ /.*[A-Z0-9_-]+/
        x += 1
      end

      runner = Runner.new(@parser, @cmd_name, action.args, @opts)
      runner.run
    end

    def do_countdown(action)
      require "clibuddy/formatters/countdown"
      cd = Formatters::Countdown.new(action.args, action.msg)
      cd.render
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
        action.ui = ::TTY::Spinner.new(":spinner #{format(action.msg)}", format: :spin)
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
        action.ui = ::TTY::Spinner.new(":spinner #{format(action.msg)}", format: :spin)
        action.ui.success
      end
    end

    def do_table(action)
      p = Pastel.new
      rows = []
      action.args.each do |line|
        rows << line.split("|").map { |v| format(v) }
      end
      # Builder has stored the header as the first row.
      header = rows.shift
      if header.empty?
        header = nil
      else
        header.map! { |val| p.decorate(val, :magenta, :underline) }
      end

      action.ui = ::TTY::Table::new header: header, rows: rows
      # Limit to 80 column width because the table will
      # expand to fill to maximum available width, and do a weird
      # centering thing - looks crappy.  This is here until
      # we can teach tty::table about making itself only big enough
      # to contain its text
      puts action.ui.render(:unicode, multiline: true,
                            resize: true, width: screen_working_width)
                       #alignments: [:right, :left],
                       #column_widths: [0, 40], indent: 4)
    end

    def screen_working_width
      @screen_working_width ||= [TTY::Screen.width, 80].min
    end

    def do_show_message(action)
      puts format(lookup_message(action.args))
    end

    def do_show_error(action)
      do_show_message(action)
    end

    def do_show_usage(_action)
      usage = Formatters::CommandUsageFormatter.new(@cmd)
      puts usage.long_usage_text
      args = TTY::Table.new(usage.arguments)
      flags = TTY::Table.new(usage.flags)

      puts "Arguments:"
      puts args.render(:basic, multiline: true, resize: true,
                       width: screen_working_width,
                       alignments: [:right, :left],
                       column_widths: [0, 40])
      puts "\nFlags:"
      puts flags.render(:basic, multiline: true, resize: true,
                       width: screen_working_width,
                       alignments: [:right, :left],
                       column_widths: [0, 40])
    end

    def maybe_delay(action)
      return if action.delay.nil?
      return if child_of_parallel?(action)
      delay_spec = action.delay
      case delay_spec[:unit]
      when :ms
        breakable_sleep(1.0 / delay_spec[:value])
      when :s
        breakable_sleep(delay_spec[:value])
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
          if @original_cmd
            raise Errors::NoMatchingFlow.new(cmd.name, "#{cmd.provided_args} via #{@original_cmd.provided_args}")
          else
            raise Errors::NoMatchingFlow.new(cmd.name, cmd.provided_args)
          end
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
    def breakable_sleep(time)
      sleep(time * (@opts[:scale] || 1.0))
    rescue Interrupt
      :interrupted
    end

  end
end
