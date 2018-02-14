require 'pastel'

module CLIBuddy
  module Formatters
    class OutputFormatter
      NEWLINE_ESCAPE = /\.n$/

      def self.format(msg, mapped_args)
        Array(msg).collect do |line|
          format_line(line, mapped_args)
        end.join("\n")
      end

      def self.format_line(line, mapped_args)
        pastel = Pastel.new
        mapped_args.each do |name, provided|
          next if provided.nil?
          line.gsub!(name, pastel.green(provided))
        end
        line.gsub!(NEWLINE_ESCAPE, "\n")
        if line.start_with?(".red")
          line = line.gsub(/^\.red\s+/, "")
          line = pastel.red(line)
        end
        line
      end
    end
  end
end
