# TODO split to files
require "tty-screen"
require "tty-table"

module CLIBuddy
  module Formatters
    class TextFormatter
      # Simple for now, we'll probably want specific handling based
      # on the type of output so that we can align things, etc
      # TODO - escape sequences, etc should not count against length.
      def self.wrap_for_term(string, first_line_prefix = "", max_length = nil)
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

    class CommandUsageFormatter
      def initialize(cmd)
        @cmd = cmd
      end
      def short_usage
        base_usage_string(:short)
      end

      def long_usage_text
        base_usage_string(:full)
      end

      def long_usage_detail_table
        rows = []
        @cmd.definition.arguments.each do |f|
          rows << [f.name, f.description.join("\n")]
        end
        @cmd.definition.flags.each do |f|
          leftside = f.short ? "--#{f.flag},-#{f.short}" : "--#{f.flag}"
          v = [leftside, f.description.join("\n")]
          rows << v
        end
        TTY::Table.new(rows)
      end


      def base_usage_string(desc_type)
        args = @cmd.definition.arguments.map {|a| a.name }.join " "
        flags = @cmd.definition.flags.map do |f|
          val = "--#{f.flag}"
          val << "|-#{f.short}" if f.short
          val << " #{f.arg}" if f.arg != nil
        end.join(" ")
        usage = TextFormatter.wrap_for_term("#{@cmd.name} #{args}#{flags}", "Usage:")
        usage << "\n"
        usage <<  TextFormatter.wrap_for_term(@cmd.usage[desc_type].join(" "), "      ")
        usage
      end

    end
  end
end
