# frozen_string_literal: true

module YandexDirectMcp
  module Tools
    module Reports
      def self.register(registry)
        registry.register(
          name: "yandex_direct_report_campaign",
          description: "Получить отчёт по кампаниям: показы, клики, расходы, CTR, средняя цена клика. " \
                       "Можно указать период и фильтр по ID кампаний.",
          input_schema: {
            type: "object",
            properties: {
              date_from: { type: "string", description: "Начало периода (YYYY-MM-DD)" },
              date_to: { type: "string", description: "Конец периода (YYYY-MM-DD)" },
              date_range: {
                type: "string",
                enum: %w[TODAY YESTERDAY LAST_7_DAYS LAST_14_DAYS LAST_30_DAYS THIS_MONTH LAST_MONTH ALL_TIME CUSTOM_DATE],
                description: "Предустановленный период (если не указаны date_from/date_to)",
                default: "LAST_7_DAYS"
              },
              campaign_ids: { type: "array", items: { type: "integer" }, description: "Фильтр по ID кампаний" }
            }
          }
        ) do |client, args|
          params = build_report_params(args,
            report_type: "CAMPAIGN_PERFORMANCE_REPORT",
            report_name: "Campaign Report",
            fields: %w[CampaignName Date Impressions Clicks Cost Ctr AvgCpc])
          client.report(params)
        end

        registry.register(
          name: "yandex_direct_report_ad",
          description: "Получить отчёт по объявлениям: показы, клики, расходы, CTR по каждому объявлению.",
          input_schema: {
            type: "object",
            properties: {
              date_from: { type: "string", description: "Начало периода (YYYY-MM-DD)" },
              date_to: { type: "string", description: "Конец периода (YYYY-MM-DD)" },
              date_range: {
                type: "string",
                enum: %w[TODAY YESTERDAY LAST_7_DAYS LAST_14_DAYS LAST_30_DAYS THIS_MONTH LAST_MONTH ALL_TIME CUSTOM_DATE],
                default: "LAST_7_DAYS"
              },
              campaign_ids: { type: "array", items: { type: "integer" }, description: "Фильтр по ID кампаний" }
            }
          }
        ) do |client, args|
          params = build_report_params(args,
            report_type: "AD_PERFORMANCE_REPORT",
            report_name: "Ad Report",
            fields: %w[AdId AdGroupName CampaignName Impressions Clicks Cost Ctr])
          client.report(params)
        end

        registry.register(
          name: "yandex_direct_report_search_queries",
          description: "Получить отчёт по поисковым запросам: какие запросы пользователей вызвали показ объявлений. " \
                       "Полезно для поиска минус-слов и новых ключевых фраз.",
          input_schema: {
            type: "object",
            properties: {
              date_from: { type: "string", description: "Начало периода (YYYY-MM-DD)" },
              date_to: { type: "string", description: "Конец периода (YYYY-MM-DD)" },
              date_range: {
                type: "string",
                enum: %w[TODAY YESTERDAY LAST_7_DAYS LAST_14_DAYS LAST_30_DAYS THIS_MONTH LAST_MONTH ALL_TIME CUSTOM_DATE],
                default: "LAST_7_DAYS"
              },
              campaign_ids: { type: "array", items: { type: "integer" }, description: "Фильтр по ID кампаний" }
            }
          }
        ) do |client, args|
          params = build_report_params(args,
            report_type: "SEARCH_QUERY_PERFORMANCE_REPORT",
            report_name: "Search Query Report",
            fields: %w[Query CampaignName Impressions Clicks Cost Ctr])
          client.report(params)
        end
      end

      def self.build_report_params(args, report_type:, report_name:, fields:)
        criteria = {}
        if args["campaign_ids"]
          criteria["Filter"] = [{ "Field" => "CampaignId", "Operator" => "IN", "Values" => args["campaign_ids"].map(&:to_s) }]
        end

        date_range = if args["date_from"] && args["date_to"]
                       criteria["DateFrom"] = args["date_from"]
                       criteria["DateTo"] = args["date_to"]
                       "CUSTOM_DATE"
                     else
                       args["date_range"] || "LAST_7_DAYS"
                     end

        {
          "SelectionCriteria" => criteria,
          "FieldNames" => fields,
          "ReportName" => "#{report_name} #{Time.now.to_i}",
          "ReportType" => report_type,
          "DateRangeType" => date_range,
          "Format" => "TSV",
          "IncludeVAT" => "YES"
        }
      end
    end
  end
end
