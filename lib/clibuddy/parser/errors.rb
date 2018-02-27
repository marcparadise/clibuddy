module CLIBuddy
  module Prototype
    module Parser
      module Errors
        class SourceError < Exception
          attr_reader :message, :id

          def initialize(id, source_line, message)
            @message = message
            @source_line = source_line
            @id = id
          end

          def line_no
            @source_line.number
          end

          def token
            @source_line.current_token
          end
        end

        class NoChildrenError < SourceError
          def initialize(source_line)
            super("CLIPARSE001", source_line, message)
          end
        end

        class NotCompleteError < SourceError
          def initialize(source_line)
            super("CLIPARSE002", source_line, "Expected end-of-line here, instead I see '#{source_line.peek}'")
          end
        end

        class NoNextTokenError < SourceError
          def initialize(source_line)
            super("CLIPARSE003", source_line, "Unexpected end of line.")
          end
        end

        class ParseError < SourceError
          def initialize(line_no, token, message)
            @line_no = line_no
            @token = token
            super("CLIPARSE999", nil, message)
          end
          def line_no
            @line_no
          end

          def token
            @token
          end
        end
      end
    end
  end
end
