
require "clibuddy/parser"
module CLIBuddy
  # TODO extend notation to include default value for param like
  # --use-secure USE_SECURE=true?
  FlowAction = Struct.new(:directive, :delay, :args, :msg, :children, :parent)

  FlowEntry = Struct.new(:expression, :actions)
  Command = Struct.new(:name, :flow, :definition, :usage)
  Message = Struct.new(:id, :lines)
  CommandDefinition = Struct.new(:arguments)
  CommandDefinitionArg = Struct.new(:name, :param, :description)
  class Builder

    TIMESPEC_MATCH = /^((\d*[.]{0,1}\d++(?!%))(s)|(\d*)(ms))$/
    attr_reader :commands, :messages
    def run(descriptor_file)
      @commands = nil
      @messages = nil
      p = Prototype::CrappyParser::load(descriptor_file)
      parse(p)
    end

    def parse_error!(parser, message)
      puts "Parse Error"
      puts "  Line: #{parser.lineno}"
      puts "  Error: #{message}"
      puts " Lib Source: #{caller(1, 1)}"
      exit 1
    end

    def parse(p)
      while p.advance_line != :EOF
        case p.advance_token
        when 'commands'
          if @commands.nil?
            @commands = parse_commands_block(p.parser_from_children)
            puts "Commands loaded!"
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

    def parse_command_definition(p)
      if p.empty?
        parse_error! p.parent, "Expected arguments or flags indented below #{p.parent.current_token}"
      end
      cmd_def = CommandDefinition.new([])
      cmd_def.arguments = []
      while p.advance_line != :EOF
        arg_name = p.advance_token
        param = nil
        # TODO - this validation is full of holes... and sometimes lies to the user.
        if p.peek_token == :EOL
          if /[A-Z0-9_-]/ !~ arg_name && /^--[a-z0-9*]+/ !~ arg_name && /^-[a-z0-9]$/ !~ arg_name
            parse_error! p, "Argument name must be capital letters and/or numbers and\n"\
              "may include hyphens or underscores. You provided: #{arg_name}"
          end
        else
          case arg_name
            # TODO revisit this regex
          when /^--[a-z0-9*]+/ # TODO - add a lookback, this will allow multiple *
            param = p.advance_token
            # when /^-[a-z0-9]/ # Allow short-flags. Could combine it to one regex above.
            #   param = p.advance_token
          else
            parse_error! p, "#{arg_name} is a parameter and not a flag. Only flags can take additional arguments. "
          end
        end
        param = nil if param == :EOL
        descriptions = parse_command_definition_description(p.parser_from_children)
        cmd_def.arguments << CommandDefinitionArg.new(arg_name, param, descriptions)
      end
      cmd_def
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
      spacer = ' '*caller.length
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
          if action.parent && action.parent.directive == ".spinner"
            # each of these under a spinner must include a timespec
            parse_timespec_msg_for_action(p, action)
          else
            action.msg = p.consume_to_eol
            if action.msg == :EOL
              parse_error! p, "Expected message to follow #{action.directive} and got nothing!"
            end
          end
        when /^[.]after$/ # shortcut for .show-text after Xs MSG
          action.directive == ".show-directive"
          parse_timespec_msg_for_action(p, action)

        when ".parallel"
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
            raise "Line #{lineno}: unexpected text '#{t}' after .show-usage"
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
