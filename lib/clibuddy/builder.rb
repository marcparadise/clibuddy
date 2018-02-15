require "clibuddy"
require "clibuddy/parser"

module CLIBuddy
  # TODO extend notation to include default value for param like
  # --use-secure USE_SECURE=true?
  FlowAction = Struct.new(:directive, :delay, :args, :msg, :children, :parent, :ui)

  FlowEntry = Struct.new(:expression, :actions)
  Message = Struct.new(:id, :lines)
  Command = Struct.new(:name, :flow, :definition, :usage)
  CommandDefinition = Struct.new(:arguments, :flags)
  CommandArg = Struct.new(:name, :description)
  CommandFlag = Struct.new(:flag, :arg, :short, :description)

  class Builder
    TIMESPEC_MATCH = /^((\d*[.]{0,1}\d++(?!%))(s)|(\d*)(ms))$/
    attr_reader :commands, :messages
    def load(descriptor_file)
      @commands = nil
      @messages = nil
      @root_parser = Prototype::CrappyParser::load(descriptor_file)
      parse(@root_parser)
    end

    def lookup_command(name)
      @commands.find { |c| c.name == name }
    end

    def parse_error!(parser, message)
      # TODO specific exceptions or at least error numbers
      # TODO - clean up exceptions to differentiate between parse errors and build errors
      # # TODO just include parser in the exceptin instead of
      # splitting out line/token info?
      raise Prototype::Parser::Errors::ParseError.new(parser.lineno, parser.current_token, message)
    end

    def parse(p)
      while p.advance_line != :EOF
        case p.advance_token
        when 'commands'
          if @commands.nil?
            @commands = parse_commands_block(p.parser_from_children)
          else
            parse_error! p, "Unexpected 'commands', 'commands' directive already given above."
          end

        when 'messages'
          if @messages.nil?
            @messages = parse_messages_block(p.parser_from_children)
          else
            parse_error! p, "Unexpected 'messages', messages already defined above."
          end
        when :EOF
          return
        else
          parse_error! p, "Unexpected '#{p.current_token}'. Expected one of 'commands', 'messages'"
        end
      end

    end

    def parse_commands_block(p, acc = [])
      if p.empty?
        parse_error! p.parent, "Expected command name, indented below 'commands'"
      end

      commands = []
      while p.advance_line != :EOF
        cmd_name = p.advance_token
        commands << parse_command_block(cmd_name, p.parser_from_children)
      end
      commands
    end

    def parse_command_block(name, p)
      if p.empty?
        parse_error! p.parent, "Expected 'flow', 'usage', or 'definition' indented below '#{name}'"
      end
      command = Command.new(name)
      while p.advance_line != :EOF

        # TODO - handle exception b/c not at end of line is possible.
        case p.advance_token
        when 'flow'
          if command.flow.nil?
            command.flow = parse_command_flow(p.parser_from_children)
          else
            raise parse_error! p, "'flow' is already defined above.\n"\
              "Please add further flow definitions to that block."
          end
        when 'usage'
          if command.usage.nil?
            command.usage = parse_command_usage(p.parser_from_children)
          else
            raise parse_error! p, "'usage' is already defined above.\n"\
              "Please add further usage content to that block."
          end
        when 'definition'
          if command.definition.nil?
            command.definition = parse_command_definition(p.parser_from_children)
          else
            raise parse_error! p, "'definition' is already defined above.\n"\
              "Please add further definition content to that block."
          end
        else
          raise parse_error! p, "After #{name}, expected one of 'flow', 'usage', or 'definition', or end of section; instead I got #{p.current_token}"
        end
      end
      command
    end

    ## --A-Z*
    def parse_command_definition(p)
      if p.empty?
        parse_error! p.parent, "Expected arguments or flags indented below #{p.parent.current_token}"
      end
      cmd_def = CommandDefinition.new([])
      cmd_def.arguments = []
      cmd_def.flags = []
      while p.advance_line != :EOF
        name = p.advance_token # Should be EOL for args, and may be a param for flags
        case name
        when /^--([a-zA-Z0-9*_-]*)/
          cmd_def.flags << extract_flag(p, $1)
        when /[^_-][A-Z0-9_-]/
          if p.peek_token != :EOL
            parse_error! p, "#{name} is an argument, but only flags can take an additional arguments."
          end
          description = parse_command_definition_description(p.parser_from_children)
          cmd_def.arguments << CommandArg.new(name, description)
        else
          parse_error! p, "#{name} must be an argument in the form ALL-CAPS-NAME or a flag in the the form --lowercase-flag-name"
        end
      end
      cmd_def
    end

    # Had a regex with lookahead to do this, but it was getting cumbersome, and this is more readable..
    def extract_flag(p, flag)
      breakdown = flag.split("*")
      if flag.match(/^---.*/)
        parse_error! p, "Flags must be prefixed with two hyphens (-); #{flag} has more than that."
      end

      if breakdown.length > 2
        parse_error! p, "The flag #{flag} can have only one *.  * is used to indicate the short flag name."
      end
      prefix, suffix = breakdown
      if suffix
        if suffix.length == 0
          parse_error! p, "The flag #{flag} has a short-name indicator (*) at the end of the flag.  This special character should be placed before the letter you wish to use as the short name for the flag."
        end
        short = suffix.slice(0)
        suffix = suffix.slice(1..-1)
        flag = "#{prefix}#{short}#{suffix}"
      else
        short = nil
      end
      # TODO validate all caps, plus optional surrounding matched [ ] around arg
      flag_arg = p.advance_token == :EOL ? nil : p.current_token
      if (p.peek_token != :EOL)
        parse_error! p, "#{flag} can take at most one argument, but more than one is provided."
      end
      description = parse_command_definition_description(p.parser_from_children)
      flag = CommandFlag.new(flag, flag_arg, short, description)
    end

    def parse_command_definition_description(p)
      if p.empty?
        parse_error! p.parent, "Expected at least one line of description indented beneath '#{p.parent.current_token}'"
      end
      parse_text_block(p)
    end


    def parse_command_usage(p)
      if p.empty?
        parse_error! p.parent, "Expected one of 'short' or 'full' indented below #{p.parent.current_token}"
      end
      short = ""
      full = ""
      while p.advance_line != :EOF
        # TODO capture if we already saw short/full in this block
        case p.advance_token
        when 'short'
          p2 = p.parser_from_children
          if p2.nil?
            parse_error! p2, "Expected at least one of line of short description indented below #{p.current_token}"
          end
          short = parse_text_block(p2)
        when 'full'
          p2 = p.parser_from_children
          if p2.nil?
            parse_error! p2, "Expected at least one of line of long description indented below #{p.current_token}"
          end
          full = parse_text_block(p2)
        else
          parse_error! p.parent, "Expected one of 'short' or 'full' indented below #{p.parent.current_token}; instead I found #{p.current_token}"
        end
      end
      {short: short, full: full}


    end


    def parse_command_flow(p)
      if p.empty?
        parse_error! p.parent, "Expected at least one 'for' mock clause after #{p.parent.current_token}."
      end
      flow_entries = []
      while p.advance_line != :EOF
        if p.advance_token == "for"
          expression = p.consume_to_eol
          if (expression == :EOL)
            parse_error! p, "Expected an expression after 'for', got nothing."
          end
          flow = FlowEntry.new(expression)
          flow.actions = parse_flow_actions(p.parser_from_children)
          flow_entries << flow
        else
          parse_error! p, "Expected 'for' expression to match on command line arguments and got #{p.current_token}"
        end
      end
      flow_entries
    end


    # Doesn't catch everything correctly (eg 1..2 works) but good enough for now
    def parse_timespec_msg_for_action(p, action)

      # Optional  "after" , depending on context
      if p.advance_token == "after"
        p.advance_token
      end
      value = nil
      unit = nil
      orig = p.current_token
      if TIMESPEC_MATCH =~ p.current_token
        if $2.nil?
          value = $4.to_i
          unit = :ms
        else
          value = $2.to_f
          unit = :s
        end
      else
        parse_error! p, "Expected a time interval in the form of X.Ys or XXXms, but got #{p.current_token}"
      end

      msg = p.consume_to_eol
      if msg == :EOL
        parse_error! p, "Expected a message to follow after #{orig} but got nothing!"
      end
      action.msg = msg
      action.delay = { value: value, unit: unit }
      action
    end

    def parse_flow_actions(p, parent_action = nil)
      # spacer = ' '*caller.length
      if p.empty?
        where = parent_action.nil? ? "'for' clause" : "#{parent_action.directive}"
        parse_error! p.parent, "Expected at least one flow action indented beneath #{where}."
      end
      actions = []
      while p.advance_line != :EOF
        action = FlowAction.new
        action.parent = parent_action
        action.directive = p.advance_token
        case p.current_token
        when ".spinner"
          action.msg = p.consume_to_eol
          action.children = parse_flow_actions(p.parser_from_children, action)
        when /^[.](show-text|success|failure)$/
          # TODO - each of these ^ is its own action which accepts a time param.
          # TODO - checking for which ones are allowed to be children
          if action.parent && (action.parent.directive == ".spinner" || action.parent.directive == ".parallel")
            # each of these under a spinner must include a timespec
            # TODO - can't any of these be delayed in any context? Why limit to spinnner
            # and parallel? While we reqiure timespec for children of par/spin, we should accept
            # it regardless.
            parse_timespec_msg_for_action(p, action)
          else
            action.msg = p.consume_to_eol
            if action.msg == :EOL
              parse_error! p, "Expected message to follow #{action.directive} and got nothing!"
            end
          end
        when /^[.]after$/ # shortcut for .show-text after Xs MSG
          action.directive == ".show-text"
          parse_timespec_msg_for_action(p, action)

        when ".parallel"
          action.msg = p.consume_to_eol

          # We'll probably want to validate that the actions we get back are
          # valid to be under parallel. Perhaps modify this parse_flow_actionrses
          # to include a list of acceptable matches? Or validate after parsing to
          # find disallowed things?
          #
          # Anyway, I'm all about quick for now because our reference file has no such errors...
          action.children = parse_flow_actions(p.parser_from_children, action)
        when ".show-error"
          action.args = p.advance_token
          # TODO validate form of error identifier
          if action.args == :EOL
            parse_error! p, "Expected message identifier after '.show-error'"
          end
        when ".show-usage"
          t = p.advance_token
          if t != :EOL
            parse_error! p, "Unexpected etext #{t} after '.show-usage'"
          end
        else
          parse_error! p, "Unknown directive #{action.directive}"
        end
        actions << action
      end
      return actions
    end

    def parse_messages_block(p)
      if p.empty?
        return []; # it is valid to have no messages in the messages section.
      end

      messages = []
      while p.advance_line != :EOF
        id = p.advance_token # TODO validate! format + not :EOL
        lines = parse_message(p.parser_from_children)
        messages << Message.new(id, lines)
      end
      messages
    end

    def parse_message(p)
      if p.empty?
        parse_error! p.parent, "Expected at least one line of message text indented beneath #{p.parent.current_token}."
      end
      parse_text_block(p)
    end

    private
    def parse_text_block(p)
      message_lines = []
      while p.advance_line != :EOF
        message_lines << p.consume_to_eol
      end
      message_lines
    end
  end
end
