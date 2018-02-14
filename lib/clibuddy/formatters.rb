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
      def short_usage_text
        args = @cmd.definition.arguments.map {|a| a.name }.join " "
        flags = @cmd.definition.flags.map do |f|
          val = "--#{f.flag}"
          val << " #{f.arg}" if f.arg?
        end.join(" ")

        usage = TextFormatter.wrap_for_term("#{@cmd.name} #{args}#{flags}", "Usage:")
        usage << "\n"
        usage <<  TextFormatter.wrap_for_term(@cmd.usage[:short].join(" "), "      ")
        usage << "\n"
      end

      def long_usage_text
        args = @cmd.definition.arguments.map {|a| a.name }.join " "
        flags = " [options...]"
        usage = TextFormatter.wrap_for_term("#{@cmd.name} #{args}#{flags}", "Usage:")
        usage << "\n"
        usage <<  TextFormatter.wrap_for_term(@cmd.usage[:full].join(" "), "      ")
        usage << "\n"
      end

      def arguments
        rows = []
        @cmd.definition.arguments.each do |f|
          rows << ["#{f.name}  ", f.description.join(" ")]
        end
        rows
      end

      def flags
        rows = []
        @cmd.definition.flags.each do |f|
          leftside = f.short ? "--#{f.flag}, -#{f.short}" : "--#{f.flag}"
          leftside = f.arg ? "#{leftside} #{f.arg}" : leftside
          rightside = f.description.join(" ")
          rows << ["#{leftside}  ",rightside]
        end
        rows
      end


      def base_usage_string(desc_type)
        args = @cmd.definition.arguments.map {|a| a.name }.join " "
        if desc_type == :short
          flags = @cmd.definition.flags.map do |f|
            val = "--#{f.flag}"
            val << "|-#{f.short}" if f.short
            val << " #{f.arg}"
          end.join(" ")
        else
          flags = " [options...]"
        end

        usage = TextFormatter.wrap_for_term("#{@cmd.name} #{args}#{flags}", "Usage:")
        usage << "\n"
        usage <<  TextFormatter.wrap_for_term(@cmd.usage[desc_type].join(" "), "      ")
        usage << "\n"
      end

    end
  end
end
