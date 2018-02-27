require "clibuddy/parser/source"
require "clibuddy/parser/errors"

module CLIBuddy
  module Prototype
    module Parser
      class SourceListing
        attr_reader :current_line, :parent, :depth
        def initialize(sources = [], depth = 0, parent = nil)
          @parent = parent
          @depth = depth
          parent_info = "Parent current line# #{parent.current_line}" if parent
          # TODO not sure if this is possoible or meaningful now:
          if sources == :BOF
            raise "[SL D: #{depth}] Received unexpected BOF in child tree. #{parent_info}"
          end
          if sources == :EOF
            raise "[SL D: #{depth}] Received an empty tree for new source listing (:EOF). #{parent_info}"
          end
          @sources = sources
          @current_line = nil
        end

        def add(line)
          @sources << line
        end

        def eof?
          @sources.empty?
        end

        def bof?
          @current_line.nil?
        end

        def empty?
          eof? && bof?
        end

        # Removes current node's children and returns them.
        # advance_line must still be called to move to the next same-or-higher
        # depth line.
        def prune_children(allow_unprocessed = false)
          return :EOF if eof?
          return :BOF if bof?
          if allow_unprocessed
            return do_prune
          end
          if current_line_processed?
            return do_prune
          end

          raise Errors::NotCompleteError.new(@current_line)
        end

        def peek_line
          return :EOF if eof?
          return @sources[0]
        end

        def num_lines
          return @sources.length
        end

        def advance_line(allow_unprocessed = false)
          return :EOF if eof?
          if allow_unprocessed
            return do_advance_line
          end
          if current_line_processed?
            return do_advance_line
          end
          raise NotCompleteError.new(@current_line)
        end

        # private
        # ... but left public for testing.

        def do_prune
          # this could just return a new SourceListing
          # with the subsection?
          deeper_than = @current_line.depth
          subsection = []
          @sources = @sources.drop_while do |item|
            if item.depth  > deeper_than
              subsection << item
              true
            else
              false
            end
          end
          # puts "[SourceListing.#{__method__} D: #{depth}] REMAINING: #{@sources.length} "
          # puts "     source[0]: #{@sources[0]}"
          # puts "     source[1]: #{@sources[1]}"
          # puts "[SourceListing.#{__method__} D: #{depth}] do_prune results:"
          # subsection.each {|l| puts "    #{l}"}
          subsection

        end

        def do_advance_line
          @current_line = @sources.shift
          # puts "[SourceListing.#{__method__} D: #{depth}] Lines left: #{@sources.length}. Current is now #{@current_line}"
          @current_line
        end

        def current_line_processed?
          if @current_line.nil?
            true
          else
            @current_line.eol?
          end
        end
      end
    end
  end
end
