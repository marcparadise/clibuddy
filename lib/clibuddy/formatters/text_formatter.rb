require "tty-screen"
module CLIBuddy
  module Formatters
    class TextFormatter
      def self.format(string, first_line_prefix = "", max_length = nil)
      # Simple for now, we'll probably want specific handling based
      # on the type of output so that we can align things, etc
      # TODO - escape sequences, etc should not count against length.
      # TODO - merge this with outputformatter?
        max_w = max_length || TTY::Screen.width
        indent_s = ""
        len = first_line_prefix.length
        if len > 0
          first_line_prefix = "#{first_line_prefix} "
          len += 1
          indent_s = " "*(len)
          max_w = max_w - len
        end
        lines = string.scan(/\S.{0,#{max_w}}\S(?=\s|$)|\S+/)
        x = 0

        lines = lines.map do |line|
          filler = (x == 0 ? "#{first_line_prefix} " : indent_s)
          x += 1
          "#{filler}#{line}"
        end

        lines.join("\n")
      end
    end
  end
end
