module CLIBuddy
  class Player
    class TermTyper
      attr_accessor :term_width

      def initialize(options: {})
        require 'tty/screen'
        require 'tty/cursor'
        @cursor = TTY::Cursor
        @options = options
        @term_width = [TTY::Screen.width, 80].min
        set_default_option_value(:delay, 0.1)
      end

      def banner(message)
        require 'tty/table'
        t = TTY::Table.new
        t << [message]
        print t.render(:unicode,
                       width: term_width,
                       alignments: [:center],
                       multiline: true, resize: true)
        print "\n"
      end

      def show_pseudo_bash_prompt(post_delay = 0.0)
        print "~$ "
        sleep post_delay if post_delay > 0.0
      end

      def type(message)
        len = message.length
        x = 0
        print @cursor.show
        while (x < len) do
          print message[x]
          x += 1
          sleep optval(:delay)
        end
      rescue Interrupt
        while (x < len) do
          print message[x]
          x+=1
        end
      end

      private

      def optval(name)
        @options[name]
      end

      def set_default_option_value(option, value)
        @options[option] = value unless @options.has_key? option
      end
    end
  end
end
