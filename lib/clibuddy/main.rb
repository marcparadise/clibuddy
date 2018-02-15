require "clibuddy/builder"
require "clibuddy/runner"
require "clibuddy/generator"
require "clibuddy/parser/errors"
require "clibuddy/runner/errors"
require "tty/table"


module CLIBuddy
  class Main
    def run(action, cmd_name, args)
      @descriptor_file = "sample.txt"
      # TODO actual good handling for args, defintion file, etc.
      b = CLIBuddy::Builder.new()
      b.load("sample.txt")
      @exit_code = 1
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
        exit 1
      end
      @exit_code = 0

    rescue Prototype::Parser::Errors::SourceError => e
      puts source_parse_error(e)
    rescue Runner::Errors::EngineRuntimeError => e
      puts cli_buddy_error(e)
    ensure
      exit @exit_code
    end
    def source_parse_error(e)
      p = Pastel.new
      t = TTY::Table.new()
      t << [p.bold("Error Code "), e.id]
      t << [p.bold("File "), @descriptor_file]
      t << [p.bold("Line "), e.line_no]
      t << ["", ""]
      message = if e.token == :EOL || e.message.include?(e.token)
                  e.message
                else
                  "Near #{e.token}: #{e.message}"
                end
      t << [p.bold("Message "), message]
      msg = p.bold("File Parsing Error\n")
      msg << t.render(:unicode,
                      column_widths: [0, 40],
                      alignments: [:right, :left],
                      multiline: true, resize: true )
      msg
    end

    def cli_buddy_error(e)
      p = Pastel.new
      t = TTY::Table.new()
      t << [p.bold("Error Code "), e.id]
      t << [p.bold("File "), @descriptor_file]
      t << [p.bold("Message "), e.message]
      msg = p.bold("Runtime Error\n")
      msg << t.render(:unicode, column_widths: [0, 40],
                      alignments: [:right, :left], multiline: true, resize: true )
      msg
    end
  end
end
