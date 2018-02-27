require "clibuddy/builder"
require "fileutils"
require "clibuddy/runner/errors"
module CLIBuddy
  class Generator
    def initialize(builder, command_name)
      @builder = builder
      @command_name = command_name
    end

    def generate
      cmd = @builder.lookup_command(@command_name)
      if !cmd
        raise Runner::Errors::NoSuchCommand.new(@command_name)
        exit 1
      end
      content = command_content(@command_name)
      filename = File.join("bin", @command_name)
      File.open(filename, "w") do |f|
        f.write(content)
      end
      puts "Created command: #{filename}"
      FileUtils.chmod(0755, filename)
    end

    def command_content(command_name)
      <<EOF
#!/usr/bin/env ruby
require "rubygems"
$:.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "clibuddy/main"

ARGV.unshift "#{command_name}" # COmmand to run flows for
ARGV.unshift "run" # Action to take - run the command flow
CLIBuddy::Main.new().run(ARGV)
EOF
    end
  end
end

