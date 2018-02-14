require "clibuddy/builder"
require "clibuddy/runner"
require "clibuddy/generator"

module CLIBuddy
  class Main
    def run(action, cmd_name, args)
      # TODO actual good handling for args, defintion file, etc.
      b = CLIBuddy::Builder.new()
      b.load("sample.txt")

      case action
      when "generate"
        generator = CLIBuddy::Generator.new(b, cmd_name)
        generator.generate

      when "run"
        runner = CLIBuddy::Runner.new(b, cmd_name, args)
        runner.run

      else
        puts "Unrecognized action: #{action}"
        puts ""
        puts "Usage: clibuddy run COMMAND ARGUMENTS..."
        puts "       clibuddy generate COMMAND"
      end
    end
  end
end
