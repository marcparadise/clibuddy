# More a renderer than a formatter, but it'll do for now
#
module CLIBuddy::Formatters
  class Countdown
    attr_reader :term_width
    def initialize(duration, message)
      require 'tty/screen'
      @duration = duration
      @message = message
      @term_width = [TTY::Screen.width, 80].min
    end
    def render
      require 'tty/cursor'
      require 'pastel'
      pastel = Pastel.new
      cursor = TTY::Cursor
      org_msg = @message.dup
      print "\n\n\n"
      print cursor.save
      puts cursor.hide
      # Center among our newly created blank lines:
      # for some reason I didn't care to explore cursor.move(0,-2) isn't.
      print cursor.prev_line
      print cursor.prev_line
      print cursor.column(term_width/2 - org_msg.length / 2)
      print format(org_msg)
      print cursor.next_line

      x = @duration
      while x >= 0
        if x == 0
          len = "Continuing now.".length
          msg = format(pastel.decorate("Continuing now.", :magenta, :bold) )
        else
          label = x.to_int == 1 ? "second" : "seconds"
          len  = "Continuing in #{x.to_int} #{label}".length
          msg = format(pastel.decorate("Continuing in #{x.to_int} #{label}", :magenta, :bold))
        end
        print cursor.clear_line
        print cursor.column(term_width/2 - len/2)
        print msg
        if x > 0
          if breakable_sleep(1) == :interrupted
            x = 0
          end
        end
        x-=1
      end
      print cursor.show
      print cursor.restore
    end
    def breakable_sleep(time)
      sleep(time * (1.0))
    rescue Interrupt
      :interrupted
    end
  end
# TODO copypasta from builder, consolidate
end

