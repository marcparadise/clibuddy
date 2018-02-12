require "clibuddy/parser/errors"

module CLIBuddy
  module Prototype
    module Parser
      class SourceLine
        attr_reader :current_token, :number, :depth
        attr_reader :children

        def initialize(line_no, level, text)
          #puts "Adding '#{line_no} #{level} #{text}"
          @children = []
          @eol = false
          @past_tokens = []
          @text = text
          @number = line_no
          @depth = level
          # TODO - split further to remove comments (allow for escaping)
          @tokens = @text.split(/[\s]+/)
        end

        def to_s
          "L#{number} D#{depth} #{@tokens.length} tokens, first: #{@tokens[0]} "
        end

        # Returns a string.  Advances current position to end of line.
        def join_remaining_tokens
          @tokens.each {|t| @past_tokens << t }
          joint = @tokens.join(" ")
          @tokens = []
          joint
        end

        def next_token
          return :EOL if eol?
          tok = @tokens.shift
          @past_tokens.unshift @current_token
          @current_token = tok
        end

        def peek
          return :EOL if eol?
          @tokens[0]
        end

        # Is the current_token the last token in this line?
        def eol?
          @tokens.empty?
        end
      end
    end
  end
end
