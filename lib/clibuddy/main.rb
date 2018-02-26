require "clibuddy/builder"
require "clibuddy/runner"
require "clibuddy/generator"
require "clibuddy/parser/errors"
require "clibuddy/runner/errors"
require "tty/table"
require "optparse"

module CLIBuddy
  class Main
    def run(argv)
      @descriptor_file = "sample.txt"
      # TODO actual good handling for args, defintion file, etc.
      @opt_parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER
Usage: clibuddy [options] run COMMAND ARGUMENTS...
       clibuddy [options] generate COMMAND

Options:
BANNER
        opts.on("-f PATH", "--file PATH", "Buddy file with command description") do |v|
          @descriptor_file = v
        end
      end

      i = argv.find_index {|a| a == "run" || a == "generate"}
      if i.nil?
        puts "Must use action 'run' or 'generate'"
        puts @opt_parser.banner
        exit 1
      end
      buddy_args = argv.slice(0, i)
      action = argv[i]
      cmd_name = argv[i+1]
      cmd_args = argv[i+2..-1]

      @opt_parser.parse!(buddy_args)

      b = CLIBuddy::Builder.new()
      b.load(@descriptor_file)
      case action
      when "generate"
        generator = CLIBuddy::Generator.new(b, cmd_name)
        generator.generate
      when "run"
        runner = CLIBuddy::Runner.new(b, cmd_name, cmd_args)
        runner.run
      else

      end
      exit 0
    rescue Prototype::Parser::Errors::SourceError => e
      puts source_parse_error(e)
    rescue Runner::Errors::EngineRuntimeError => e
      puts cli_buddy_error(e)
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
