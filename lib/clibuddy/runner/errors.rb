module CLIBuddy
  class Runner
    module Errors

      class EngineRuntimeError < Exception
        attr_reader :id, :message
        def initialize(id, message)
          @id = id
          @message = message
        end
      end

      class NoMatchingFlow < EngineRuntimeError
        attr_reader :cmd_name, :given_args
        def initialize(cmd_name, given_args)
          @cmd_name = cmd_name
          @given_args = given_args
          msg = "I could not find a flow defined for #{cmd_name} which matches '#{given_args.join(" ")}'.\n"
          msg << "Try adding a default flow handler of 'flow ANY' to avoid this message' "
          super("CLIRUN001", msg)
        end
      end

      class NoSuchCommand < EngineRuntimeError
        attr_reader :cmd_name
        def initialize(cmd_name)
          msg = "I could not find any command named '#{cmd_name}'"
          @cmd_name = cmd_name
          super("CLIRUN002", msg)
        end
      end
    end
  end
end
