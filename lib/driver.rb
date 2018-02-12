require "clibuddy/builder"
require "clibuddy/runner"

b = CLIBuddy::Builder.new()
begin
  b.run("sample.txt")
  require 'pp'
  # pp b.commands
  puts "*"*20
  runner = CLIBuddy::Runner.new(b, ARGV[0], ARGV[1..-1])
  runner.run
  # puts "*"*20
  # puts "Commands: #{b.commands}"
  # puts "*"*20
  # puts "Messages: #{b.messages}"
  # puts "*"*20

  # parse the ARGV
  # compare provided commands to the parsed command
  # if it matches, follow the parsed flow

# rescue => e
#   puts "Exception: #{e.message}"
#   puts e.backtrace
#   puts "State: "
#   puts b.commands
#   puts b.messages
end
