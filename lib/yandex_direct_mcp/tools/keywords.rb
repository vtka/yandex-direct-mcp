# frozen_string_literal: true

module YandexDirectMcp
  module Tools
    module Keywords
      def self.register(registry)
        registry.register(
          name: "yandex_direct_keywords_get",
          description: "Получить ключевые фразы. Фильтр по ID кампании, группы или конкретным ID фраз.",
          input_schema: {
            type: "object",
            properties: {
              campaign_ids: { type: "array", items: { type: "integer" }, description: "ID кампаний" },
              ad_group_ids: { type: "array", items: { type: "integer" }, description: "ID групп" },
              ids: { type: "array", items: { type: "integer" }, description: "ID ключевых фраз" },
              limit: { type: "integer", description: "Макс. кол-во (по умолч. 500)", default: 500 }
            }
          }
        ) do |client, args|
          criteria = {}
          criteria["CampaignIds"] = args["campaign_ids"] if args["campaign_ids"]
          criteria["AdGroupIds"] = args["ad_group_ids"] if args["ad_group_ids"]
          criteria["Ids"] = args["ids"] if args["ids"]

          client.call("keywords", "get", {
            "SelectionCriteria" => criteria,
            "FieldNames" => %w[Id Keyword AdGroupId CampaignId State Status Bid],
            "Page" => { "Limit" => args["limit"] || 500 }
          })
        end

        registry.register(
          name: "yandex_direct_keywords_add",
          description: "Добавить ключевые фразы в группу объявлений. " \
                       "Можно добавить несколько фраз сразу в одну или разные группы.",
          input_schema: {
            type: "object",
            properties: {
              keywords: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    keyword: { type: "string", description: "Ключевая фраза" },
                    ad_group_id: { type: "integer", description: "ID группы объявлений" }
                  },
                  required: %w[keyword ad_group_id]
                },
                description: "Массив ключевых фраз"
              }
            },
            required: %w[keywords]
          }
        ) do |client, args|
          items = args["keywords"].map do |kw|
            { "Keyword" => kw["keyword"], "AdGroupId" => kw["ad_group_id"] }
          end

          client.call("keywords", "add", { "Keywords" => items })
        end

        registry.register(
          name: "yandex_direct_keywords_update",
          description: "Обновить текст ключевых фраз.",
          input_schema: {
            type: "object",
            properties: {
              keywords: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    id: { type: "integer", description: "ID ключевой фразы" },
                    keyword: { type: "string", description: "Новый текст фразы" }
                  },
                  required: %w[id keyword]
                },
                description: "Массив обновлений"
              }
            },
            required: %w[keywords]
          }
        ) do |client, args|
          items = args["keywords"].map do |kw|
            { "Id" => kw["id"], "Keyword" => kw["keyword"] }
          end

          client.call("keywords", "update", { "Keywords" => items })
        end

        registry.register(
          name: "yandex_direct_keywords_delete",
          description: "Удалить ключевые фразы.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID фраз для удаления" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("keywords", "delete", { "SelectionCriteria" => { "Ids" => args["ids"] } })
        end

        registry.register(
          name: "yandex_direct_keywords_suspend",
          description: "Остановить показы по ключевым фразам.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID фраз" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("keywords", "suspend", { "SelectionCriteria" => { "Ids" => args["ids"] } })
        end

        registry.register(
          name: "yandex_direct_keywords_resume",
          description: "Возобновить показы по ключевым фразам.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID фраз" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("keywords", "resume", { "SelectionCriteria" => { "Ids" => args["ids"] } })
        end

        registry.register(
          name: "yandex_direct_keywords_set_bids",
          description: "Установить ставки для ключевых фраз. Ставки в микроединицах (1 тенге = 1000000). " \
                       "Например, 30 тенге = 30000000.",
          input_schema: {
            type: "object",
            properties: {
              bids: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    keyword_id: { type: "integer", description: "ID ключевой фразы" },
                    search_bid: { type: "integer", description: "Ставка для поиска в микроединицах" },
                    network_bid: { type: "integer", description: "Ставка для сетей в микроединицах (опционально)" }
                  },
                  required: %w[keyword_id search_bid]
                },
                description: "Массив ставок"
              }
            },
            required: %w[bids]
          }
        ) do |client, args|
          items = args["bids"].map do |b|
            item = { "KeywordId" => b["keyword_id"], "SearchBid" => b["search_bid"] }
            item["NetworkBid"] = b["network_bid"] if b["network_bid"]
            item
          end

          client.call("keywordbids", "set", { "KeywordBids" => items })
        end
      end
    end
  end
end
