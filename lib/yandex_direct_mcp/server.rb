# frozen_string_literal: true

require "json"

module YandexDirectMcp
  class Server
    PROTOCOL_VERSION = "2024-11-05"

    def initialize(client:)
      @client = client
      @registry = ToolRegistry.new
      @initialized = false
      register_all_tools
    end

    def run
      $stderr.puts "Yandex Direct MCP Server запущен (stdio)"

      $stdin.each_line do |line|
        line = line.strip
        next if line.empty?

        begin
          request = JSON.parse(line)
          response = handle_request(request)
          write_response(response) if response
        rescue JSON::ParserError => e
          write_response(error_response(nil, -32_700, "Parse error: #{e.message}"))
        rescue => e
          $stderr.puts "Error: #{e.message}\n#{e.backtrace&.first(5)&.join("\n")}"
          write_response(error_response(nil, -32_603, "Internal error: #{e.message}"))
        end
      end
    end

    private

    def handle_request(request)
      id = request["id"]
      method = request["method"]
      params = request["params"] || {}

      case method
      when "initialize"
        handle_initialize(id, params)
      when "notifications/initialized"
        nil # notification, no response
      when "tools/list"
        handle_tools_list(id)
      when "tools/call"
        handle_tool_call(id, params)
      when "ping"
        jsonrpc_response(id, {})
      else
        error_response(id, -32_601, "Method not found: #{method}")
      end
    end

    def handle_initialize(id, _params)
      @initialized = true
      jsonrpc_response(id, {
        protocolVersion: PROTOCOL_VERSION,
        capabilities: { tools: { listChanged: false } },
        serverInfo: { name: "yandex-direct-mcp", version: "1.0.0" }
      })
    end

    def handle_tools_list(id)
      jsonrpc_response(id, { tools: @registry.tool_definitions })
    end

    def handle_tool_call(id, params)
      tool_name = params["name"]
      arguments = params["arguments"] || {}
      arguments = JSON.parse(arguments) if arguments.is_a?(String)

      tool = @registry.find(tool_name)
      unless tool
        return jsonrpc_response(id, {
          content: [{ type: "text", text: "Инструмент '#{tool_name}' не найден" }],
          isError: true
        })
      end

      begin
        result = tool.handler.call(@client, arguments)
        jsonrpc_response(id, {
          content: [{ type: "text", text: result.is_a?(String) ? result : JSON.pretty_generate(result) }]
        })
      rescue => e
        jsonrpc_response(id, {
          content: [{ type: "text", text: "Ошибка: #{e.message}" }],
          isError: true
        })
      end
    end

    def register_all_tools
      Tools::Campaigns.register(@registry)
      Tools::AdGroups.register(@registry)
      Tools::Ads.register(@registry)
      Tools::Keywords.register(@registry)
      Tools::Reports.register(@registry)
      Tools::Dictionaries.register(@registry)
    end

    def jsonrpc_response(id, result)
      { jsonrpc: "2.0", id: id, result: result }
    end

    def error_response(id, code, message)
      { jsonrpc: "2.0", id: id, error: { code: code, message: message } }
    end

    def write_response(response)
      json = JSON.generate(response)
      $stdout.write(json + "\n")
      $stdout.flush
    end
  end
end
