require 'clibuddy/player/errors'
require 'clibuddy/player/term_typer'
module CLIBuddy
  class Player
    def initialize(builder, command, filter, opts = {} )
      require 'tty/screen'
      require 'tty/cursor'
      @cursor = TTY::Cursor
      @term_width = [TTY::Screen.width, 80].min

      @opts = opts
      @builder = builder

      # TODO this and even in run/generate - we could just pass in the resolved command so
      # each one doesn't have to look it up separtely.
      @cmd_name = command
      @autoplay_delay = opts[:autoplay_delay] || 10.0
      # TODO 'join' is a workaround to remaining args always coming in as a list.
      filter_text = filter.join(" ").gsub("*", ".*").gsub("?", ".?")
      @filter = filter_text.length > 0 ? Regexp.new(filter_text) : /.*/
      @opts[:scale] ||= 1.0
      @tt = TermTyper.new(@opts[:scale])

    end

    def play
      require 'clibuddy/runner'
      flows = find_flows()
      flow_pos = 0
      num_flows = flows.length

      # First, find out what they want to play
      # For each thing to play:
      #   - clear the screen
      #   - show the banner  if banner is enabled
      #   - run the actions
      #   - at bottom of screen:
      #   - wait for keypress:
      #       'R" run again
      #       'P" previous flow
      #       "N" next flow
      #       any other key - next

      while flow_pos != :stop
        reset_screen
        flow = flows[flow_pos]
        if @opts[:banner]
          show_banner(flow.description || flow.expression, flow_pos, num_flows)
        end

        run_flow(flow)
        case next_action(flow_pos, num_flows)
        when :quit
          flow_pos = :stop
        when :next
          flow_pos += 1
        when :prev
          flow_pos -= 1
        when :replay
        end
      end
    end


    def find_flows
      flows = []
      cmd = @builder.lookup_command(@cmd_name)
      cmd.flow.each do |flow|
        flows << flow if @filter =~ flow.expression
      end
      flows
    end

    def run_flow(flow)
      match_on = flow.expression.gsub(/\*/, 'somevalue')
      to_type = "#{@cmd_name} #{match_on}"
      @tt.show_pseudo_bash_prompt
      @tt.type "#{to_type}\n"
      # TODO - can't directly use expression -- need a strategy for wildcard args.
      runner = CLIBuddy::Runner.new(@builder, @cmd_name,
                                    match_on.split(" "),
                                    scale: @opts[:scale])
      runner.run
      @tt.show_pseudo_bash_prompt
      puts @cursor.show
      print "\n"
    end

    def reset_screen
      print @cursor.clear_screen
      print @cursor.column(0)
      print @cursor.row(0)
      # TODO - key shortcuts at the bottom?
    end

    def show_banner(msg, num, count)
      require 'pastel'
      @tt.banner("#{Pastel.new.decorate("Current Flow (#{num + 1} / #{count})", :underline)}\n#{msg}")
      sleep 1.0*@opts[:scale]
    end

    def next_action(pos, count)
      if @opts[:autoplay]
        countdown_to_next(pos, count)
      else
        prompt_next(pos, count)
      end
    end

    def countdown_to_next(pos, count)
      require 'clibuddy/formatters/countdown'
      if pos + 1 == count
        return :quit
      end
      cd = Formatters::Countdown.new(@autoplay_delay, "Next up: flow #{pos + 1} / #{count}.")
      if cd.render == :interrupted
        return :quit
      end
      return :next
    rescue Interrupt
      return :quit
    end

    def prompt_next(pos, count)
      # Ideally I'd like to offer a menu with a timeout - might have to compromise
      # and do a simple keystroke listener because the API doesn't seem to offer the former.
      require 'tty/prompt'

      last_flow = pos+1 == count

      choices = []
      choices << { name: "Previous", value: :prev } if pos > 0
      choices << { name: "Replay", value: :replay}
      choices << { name: "Next", value: :next} unless last_flow
      choices << { name: "Quit", value: :quit}

      prompt = TTY::Prompt.new
      prompt.select("On flow #{pos + 1} out of #{count}. What would you like to do?") do |menu|
        menu.enum('.')
        choices.each do |c|
          # API docs suggest I can just do menu.choice choice, but that displays the actual hash.
          menu.choice c[:name], c[:value]
        end
        # We want the default to always be 'next' unless we are on the last flow, then we want it to be 'quit'
        default = choices.length
        default -= 1 unless last_flow
        menu.default(default)
      end
    end
  end
end
