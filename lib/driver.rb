require "bundler/setup"
require "parser"
require "directives"

parser = CrappyParser.new
parser.load("sample.txt")
root = RootDirective.new(parser)
root.parse(parser)

puts root
