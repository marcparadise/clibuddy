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
      @descriptor_file = "sample.bdy"
      @scale = 1.0

      # TODO actual good handling for args, defintion file, etc.
      @opt_parser = OptionParser.new do |opts|
        opts.banner = <<-BANNER
Usage: clibuddy [options] run COMMAND ARGUMENTS...
       clibuddy [options] generate COMMAND

Options:
BANNER
        opts.on('-s SCALE', "--scale SCALE", "Speed at which to play back delays, default 1.0") do |v|
          begin
            # TODO validate not huge, not negative...
            @scale = Float(v)
          rescue
            puts "WARNING: #{v} not a valid scale. Use number such as 0, 0.5, 1.75. Curently using default of 1.0"
          end
        end

        opts.on("-f PATH", "--file PATH", "Buddy file with command description") do |v|
          @descriptor_file = v
        end
      end

      permitted_cmds = %w{run generate play}
      i = argv.find_index {|a| permitted_cmds.include? a}
      if i.nil?
        puts "Action is required."
        puts "Supported actions are:"
        permitted_cmds.sort.each {|c| puts " - #{c}"}

        puts @opt_parser.banner
        exit 1
      end
      buddy_args = argv.slice(0, i)
      action = argv[i]
      cmd_name = argv[i+1]
      cmd_args = argv[i+2..-1]

      @opt_parser.parse!(buddy_args)

      unless File.exist?(@descriptor_file)
        raise Runner::Errors::DescriptorFileNotFound.new(@descriptor_file)
      end

      b = CLIBuddy::Builder.new()
      b.load(@descriptor_file)
      case action
        #TODO subcommand this!
        #TODO defer include loading, it takes almost a second per run to start doing things
      when "generate"
        generator = CLIBuddy::Generator.new(b, cmd_name, @descriptor_file)
        generator.generate
      when "run"
        runner = CLIBuddy::Runner.new(b, cmd_name, cmd_args, scale: @scale)
        runner.run
      when "play"
        # player = CLIBuddy::Player.new(b, cmd_name, cmd_args)
        # player.play
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
