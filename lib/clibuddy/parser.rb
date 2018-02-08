module CLIBuddy
  module ProtoType
    class CrappyParser
      attr_accessor :lineno, :current_token
      def initialize()
        @lineno = 0
        @remaining_line = ""
      end

      def load(filename)
        @content = File.readlines('foo')
        self
      end

      def peek_token
        token, _ = next_token(true)
        token
      end

      def advance_token
        @cur_token, @remaining_line = next_token(false)
        @cur_token
      end

      # This is a bit different - really only
      # used when parsing error messages,
      # which does not have the same rules
      # as directives... here, we literally just
      # grab the next line without worrying about
      # its content.
      def absolute_next_line(peek)
        @lineno += 1
        if @lineno >= @content.size
          nil
        else
          @remaining_line = @content[@lineno]
          @remaining_line
        end
      end

      def remaining_line(peek)
        if peek
          @remaining_line
        else
          val = @remaining_line
          @remaining_line = ""
          advance_line
          val
        end
      end

      private

      def peek_line
        n = next_content_lineno
        if n == :EOF
          nil
        else
          content[n]
        end
      end

      def advance_line
        @lineno = next_content_lineno
        @remaining_line = content[@lineno]
      end


      def next_token(peek)
        local_line = if @remaining_line =~ /^[\s]*([#]+.*)?$/
                         if (peek)
                           peek_line()
                         else
                           advance_line()
                         end
                     else
                       @remaining_line
                     end
        local_line.split(/^\s/, 2)
      end

      def next_content_lineno
        matching_line = lineno
        max = content.size - 1
        while matching_line < max
          matching_line += 1
          next if content[matching_line] =~ /^[\s]*([#]+.*)?$/
          return matching_line
        end
        return :EOF
      end
    end

  end
end
