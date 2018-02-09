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

          def line_number
            @source_line.number
          end

          def active_token
            @source_line.current_token
          end

          def to_s
            "Error: #{name}\nLine #{line_number}, near #{active_token}:\n\n #{message}"
          end
        end

        class NoChildrenError < SourceError
          def initialize(source_line)
            super("CLISE001", source_line, message)
          end
        end

        class NotCompleteError < SourceError
          def initialize(source_line)
            super("CLISE002", source_line, "Expected end-of-line here, instead I see '#{source_line.peek}'")
          end
        end

        class NoNextTokenError < SourceError
          def initialize(source_line)
            super("CLISE003", source_line, "Unexpected end of line.")
          end
        end
      end
    end
  end
end



