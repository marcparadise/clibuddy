require "clibuddy/formatters/text_formatter"

module CLIBuddy
  module Formatters
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

        usage = TextFormatter.format("#{@cmd.name} #{args}#{flags}", "Usage:")
        usage << "\n"
        usage <<  TextFormatter.format(@cmd.usage[:short].join(" "), "      ")
        usage << "\n"
      end

      def long_usage_text
        args = @cmd.definition.arguments.map {|a| a.name }.join " "
        flags = " [options...]"
        usage = TextFormatter.format("#{@cmd.name} #{args}#{flags}", "Usage:")
        usage << "\n"
        usage <<  TextFormatter.format(@cmd.usage[:full].join(" "), "      ")
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

        usage = TextFormatter.format("#{@cmd.name} #{args}#{flags}", "Usage:")
        usage << "\n"
        usage <<  TextFormatter.format(@cmd.usage[desc_type].join(" "), "      ")
        usage << "\n"
      end

    end
  end
end
