require "clibuddy/parser/errors"
require "clibuddy/parser/source_listing"
require "clibuddy/parser/source"

module CLIBuddy
  module Prototype
    class CrappyParser
      attr_reader :parent
      def initialize(sources, parent = nil)
        @parent = parent
        @listing = sources
        @depth = 0;
        tmp = self
        while (tmp.parent)
          @depth += 2 # Keep it in line with indentation for now
          tmp = tmp.parent
        end
      end

      def self.load(filename)
        listing = Parser::SourceListing.new([])
        line_no = 0
        File.readlines(filename).map do |line|
          line = line.rstrip
          line_no += 1
          if /^([\s]*)([^#].*)/.match(line)
            # $1 - leading whitepsace
            # $2 - anything that isn't whitespace
            listing.add(Parser::SourceLine.new(line_no, $1.length, $2.rstrip))
          else
            # Line is only whitespace, or whitespace and comment.
            next
          end
        end
        CrappyParser.new(listing)
      end

      def parser_from_children
        children = @listing.prune_children()
        listing = Parser::SourceListing.new(children, depth + 2, @listing)
        CrappyParser.new(listing, self)
      end

      def advance_line(allow_unprocessed = false)
        @listing.advance_line
      end

      def debug_num_lines
        @listing.num_lines
      end

      def current_token
        @listing.bof? ? :BOF : @listing.current_line.current_token
      end

      def advance_token
        @listing.bof? ? :BOF : @listing.current_line.next_token
      end

      def consume_to_eol
        @listing.bof? ? :EOL : @listing.current_line.join_remaining_tokens
      end

      def empty?
        @listing.nil? || (@listing.bof? && @listing.eof?)
      end

      def eol?
        @listing.bof? ? false : listing.current_line.eol?
      end

      def peek_token
        @listing.bof? ? :BOF : @listing.current_line.peek
      end

      def lineno
        @listing.bof? ? 0 : @listing.current_line.number
      end


      def depth
        @listing.bof? ? 0 : @listing.current_line.depth
      end

      # def has_children?
      #   @listing.eof? ? false : @listing.peek_line.depth > depth
      # end
    end
  end
end
