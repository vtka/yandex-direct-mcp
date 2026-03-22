# frozen_string_literal: true

module YandexDirectMcp
  class ToolRegistry
    Tool = Data.define(:name, :description, :input_schema, :handler)

    def initialize
      @tools = {}
    end

    def register(name:, description:, input_schema:, &handler)
      @tools[name] = Tool.new(name: name, description: description, input_schema: input_schema, handler: handler)
    end

    def list
      @tools.values
    end

    def find(name)
      @tools[name]
    end

    def tool_definitions
      @tools.values.map do |tool|
        {
          name: tool.name,
          description: tool.description,
          inputSchema: tool.input_schema
        }
      end
    end
  end
end
