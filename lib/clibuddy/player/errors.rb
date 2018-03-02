module CLIBuddy
  class Player
    module Errors
      # TODO - following htis same pattern in
      # three different module error submods now...

      class PlayerArgumentError < Exception
        attr_reader :id, :message
        def initialize(id, message)
          @id = id
          @message = message
        end
      end

    end
  end
end
