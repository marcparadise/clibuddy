require "parser"

module CLIBuddy
  module ProtoType
  class Runner
    def go()
      parser = CrappyParser.new
      parser.load("sample.txt")
    end
  end

  class Directive
    attr_reader :parser
    def initialize(parser)
      @parser = parser
    end
    def process(token)
      raise "Not implemented"
    end
  end

  class RootDirective < Directive
    def initialize(parser)
      @errors = {}
      @commands = {}
      super(parser)
    end

    def process(token)
      case token
      when nil
        return
      when /command/
        cmd = CommandDirective.new(parser)
        @commands[name] = cmd
        cmd.process(parser.advance_token)
      when /errors/
        err = ErrorMsg.new(parser)
        err.process(parser.next_token)
        @errors[err.id] = err
      when nil
        puts "Reached nil token, complete."
      else
        raise "Line #{parser.lineno}: expected either 'command' or 'errors', got '#{token}'"
      end
      process(parser.advance_token)
    end
  end
  class FlowDirective < Directive
  end
  class CommandDirective < Directive
    def initialize(parser)
      @name =nil
      @definition = nil
      @description = {}
      @flow = {}
      super(parser)
    end
    def process(token)
      case token
      when nil
        # TODO - a command with no definition or flow is an error
        return
      # Next acceptable tokens : flow or definition
      when "flow"
        FlowDirective =  FlowDirective.new(
        case absolute_next_line(true)
          case "definition"

      when "definition"
      when "usage"

    end
  end

  class ErrorMsg
    def initialize(name, parser)
      @content = []
      super(parser)
    end
  end
