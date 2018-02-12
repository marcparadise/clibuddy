
FlowAction = Struct.new(:directive,
                        :delay,
                        :args,
                        :msg,
                        :children,
                        :parent)
FlowEntry = Struct.new(:expression, :actions)
Command = Struct.new(:name, :flow,
                     :definition, :usage)
Message = Struct.new(:id, :lines)
CommandDefinition = Struct.new(:arguments)
CommandDefinitionArg = Struct.new(:name,
                                  :param, :description)
