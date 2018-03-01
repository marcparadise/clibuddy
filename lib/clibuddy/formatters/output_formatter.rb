require 'pastel'

module CLIBuddy
  module Formatters
    class OutputFormatter
      TAB_ESCAPE = /\.t /
      NEWLINE_ESCAPE = /\.n$/
      ENV_MARKER = /(.*)\.e\s(\w+)(.*)/

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
        line.gsub!(TAB_ESCAPE, "\t")
        # This works for simple inline coloring (and later formatting)
        # but wont' work for nested format tags.
        while line =~ /(.*)\.(red|green|blue|yellow|magenta|cyan|white)(.*)(\.x|$)(.*)$/

          # $1 - text prefix
          # $2 - color identifier
          # $3 - text to be colored
          # $4 - end marker or nil
          # $5 - remaining uncolored text or nil
          colored_text = pastel.send($2.to_sym, $3)
          line = "#{$1}#{colored_text}#{$5}"
        end
        while line =~ ENV_MARKER
          # $1 - text prefix
          # $2 - env var name
          # $3 - trailing text
          val = ENV[$2] || pastel.red("env var not found: #{$2}")
          line = "#{$1}#{val}#{$3}"
        end

        line
      end
    end
  end
end
