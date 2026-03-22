# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

module YandexDirectMcp
  class Client
    PRODUCTION_URL = "https://api.direct.yandex.com/json/v5"
    SANDBOX_URL = "https://api-sandbox.direct.yandex.com/json/v5"

    attr_reader :token, :base_url

    def initialize(token:, sandbox: false)
      @token = token
      @base_url = sandbox ? SANDBOX_URL : PRODUCTION_URL
    end

    def call(service, method, params = {})
      uri = URI("#{base_url}/#{service}")
      body = { method: method, params: params }

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json; charset=utf-8"
      request["Accept-Language"] = "ru"
      request.body = JSON.generate(body)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.open_timeout = 15
        http.read_timeout = 60
        http.request(request)
      end

      parse_response(response)
    end

    def report(params)
      uri = URI("#{base_url}/reports")

      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Content-Type"] = "application/json; charset=utf-8"
      request["Accept-Language"] = "ru"
      request["processingMode"] = "auto"
      request["returnMoneyInMicros"] = "false"
      request["skipReportHeader"] = "true"
      request["skipReportSummary"] = "true"
      request.body = JSON.generate(params: params)

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.open_timeout = 15
        http.read_timeout = 120
        http.request(request)
      end

      case response.code.to_i
      when 200
        { success: true, data: response.body, units: response["Units"] }
      when 201
        { success: true, data: response.body, units: response["Units"], status: "report_ready" }
      when 202
        retry_in = response["retryIn"] || "5"
        { success: false, retry_in: retry_in.to_i, status: "processing" }
      else
        { success: false, error: response.body }
      end
    end

    private def parse_response(response)
      data = JSON.parse(response.body)
      units = response["Units"]

      if data["error"]
        {
          success: false,
          error_code: data["error"]["error_code"],
          error_message: data["error"]["error_string"],
          error_detail: data["error"]["error_detail"],
          units: units
        }
      else
        { success: true, data: data["result"], units: units }
      end
    rescue JSON::ParserError => e
      { success: false, error_message: "JSON parse error: #{e.message}" }
    end
  end
end
