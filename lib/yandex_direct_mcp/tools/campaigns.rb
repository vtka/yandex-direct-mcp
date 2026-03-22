# frozen_string_literal: true

module YandexDirectMcp
  module Tools
    module Campaigns
      def self.register(registry)
        registry.register(
          name: "yandex_direct_campaigns_get",
          description: "Получить список рекламных кампаний. Можно фильтровать по ID, типу, состоянию. " \
                       "Возвращает название, статус, бюджет, статистику.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID кампаний (опционально)" },
              states: {
                type: "array",
                items: { type: "string", enum: %w[ON OFF SUSPENDED ENDED CONVERTED ARCHIVED] },
                description: "Фильтр по состоянию"
              },
              limit: { type: "integer", description: "Макс. кол-во результатов (по умолч. 100)", default: 100 }
            }
          }
        ) do |client, args|
          criteria = {}
          criteria["Ids"] = args["ids"] if args["ids"]
          criteria["States"] = args["states"] if args["states"]

          client.call("campaigns", "get", {
            "SelectionCriteria" => criteria,
            "FieldNames" => %w[Id Name StartDate EndDate State Status Type DailyBudget Statistics],
            "Page" => { "Limit" => args["limit"] || 100 }
          })
        end

        registry.register(
          name: "yandex_direct_campaigns_add",
          description: "Создать новую рекламную кампанию. Укажите название, дату старта, дневной бюджет. " \
                       "Бюджет в валюте аккаунта, конвертируется в микроединицы автоматически.",
          input_schema: {
            type: "object",
            properties: {
              name: { type: "string", description: "Название кампании" },
              start_date: { type: "string", description: "Дата старта (YYYY-MM-DD)" },
              daily_budget: { type: "number", description: "Дневной бюджет в валюте аккаунта (рубли, тенге и др.)" },
              negative_keywords: {
                type: "array", items: { type: "string" },
                description: "Минус-фразы для кампании"
              }
            },
            required: %w[name start_date]
          }
        ) do |client, args|
          campaign = {
            "Name" => args["name"],
            "StartDate" => args["start_date"],
            "TextCampaign" => {
              "BiddingStrategy" => {
                "Search" => {
                  "BiddingStrategyType" => "HIGHEST_POSITION"
                },
                "Network" => {
                  "BiddingStrategyType" => "SERVING_OFF"
                }
              }
            }
          }

          if args["daily_budget"]
            budget_micros = (args["daily_budget"] * 1_000_000).to_i
            campaign["DailyBudget"] = { "Amount" => budget_micros, "Mode" => "DISTRIBUTED" }
          end

          if args["negative_keywords"]
            campaign["NegativeKeywords"] = { "Items" => args["negative_keywords"] }
          end

          client.call("campaigns", "add", { "Campaigns" => [campaign] })
        end

        registry.register(
          name: "yandex_direct_campaigns_update",
          description: "Обновить параметры кампании (название, бюджет, минус-фразы, дату окончания).",
          input_schema: {
            type: "object",
            properties: {
              id: { type: "integer", description: "ID кампании" },
              name: { type: "string", description: "Новое название" },
              daily_budget: { type: "number", description: "Новый дневной бюджет в рублях" },
              end_date: { type: "string", description: "Дата окончания (YYYY-MM-DD)" },
              negative_keywords: { type: "array", items: { type: "string" }, description: "Минус-фразы" }
            },
            required: %w[id]
          }
        ) do |client, args|
          campaign = { "Id" => args["id"] }
          campaign["Name"] = args["name"] if args["name"]
          campaign["EndDate"] = args["end_date"] if args["end_date"]

          if args["daily_budget"]
            budget_micros = (args["daily_budget"] * 1_000_000).to_i
            campaign["DailyBudget"] = { "Amount" => budget_micros, "Mode" => "DISTRIBUTED" }
          end

          if args["negative_keywords"]
            campaign["NegativeKeywords"] = { "Items" => args["negative_keywords"] }
          end

          client.call("campaigns", "update", { "Campaigns" => [campaign] })
        end

        registry.register(
          name: "yandex_direct_campaigns_delete",
          description: "Удалить кампании (переместить в архив).",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID кампаний для удаления" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("campaigns", "delete", { "SelectionCriteria" => { "Ids" => args["ids"] } })
        end

        registry.register(
          name: "yandex_direct_campaigns_suspend",
          description: "Остановить показы кампаний.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID кампаний" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("campaigns", "suspend", { "SelectionCriteria" => { "Ids" => args["ids"] } })
        end

        registry.register(
          name: "yandex_direct_campaigns_resume",
          description: "Возобновить показы кампаний.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID кампаний" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("campaigns", "resume", { "SelectionCriteria" => { "Ids" => args["ids"] } })
        end
      end
    end
  end
end
