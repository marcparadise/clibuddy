require 'pastel'

module CLIBuddy
  module Formatters
    class OutputFormatter
      TAB_ESCAPE = /\.t /
      NEWLINE_ESCAPE = /\.n$/
      ENV_MARKER = /(.*)\.e\s([a-zA-Z_]+)(.*)/

      def self.format(msg, mapped_args)
        Array(msg).collect do |line|
          format_line(line, mapped_args)
        end.join("\n")
      end

      def self.format_line(line, mapped_args)
        pastel = Pastel.new
        line.split(" ").each do |token|
          # TODO - Crappy hack in here - knowing that we often
          # put tokens inside of [ ] , we explicitly also try to match
          # on removed first/last char
          if token =~ /\[(.*)\]/
            token = $1
          end

          if mapped_args.has_key? token
            line.gsub!(/(?<!\/e)#{token}/, pastel.green(mapped_args[token]))
          end
        end
        line.gsub!(NEWLINE_ESCAPE, "\n")
        line.gsub!(TAB_ESCAPE, "    ")
        # Escaped /PARAM_NAME should be rendered without the escape
        # and without var replacement.
        line.gsub!(/\/([A-Z_-]+)/, pastel.green($1))

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
          val = ENV[$2] || pastel.red("#{$2}")
          line = "#{$1}#{val}#{$3}"
        end
        line
      end
    end
  end
end
