# frozen_string_literal: true

module YandexDirectMcp
  module Tools
    module AdGroups
      def self.register(registry)
        registry.register(
          name: "yandex_direct_adgroups_get",
          description: "Получить группы объявлений. Можно фильтровать по ID кампании или ID группы.",
          input_schema: {
            type: "object",
            properties: {
              campaign_ids: { type: "array", items: { type: "integer" }, description: "ID кампаний" },
              ids: { type: "array", items: { type: "integer" }, description: "ID групп" },
              limit: { type: "integer", description: "Макс. кол-во (по умолч. 100)", default: 100 }
            }
          }
        ) do |client, args|
          criteria = {}
          criteria["CampaignIds"] = args["campaign_ids"] if args["campaign_ids"]
          criteria["Ids"] = args["ids"] if args["ids"]

          client.call("adgroups", "get", {
            "SelectionCriteria" => criteria,
            "FieldNames" => %w[Id Name CampaignId Status Type RegionIds NegativeKeywords],
            "Page" => { "Limit" => args["limit"] || 100 }
          })
        end

        registry.register(
          name: "yandex_direct_adgroups_add",
          description: "Создать группу объявлений в кампании. Укажите название, ID кампании и регионы показа.",
          input_schema: {
            type: "object",
            properties: {
              campaign_id: { type: "integer", description: "ID кампании" },
              name: { type: "string", description: "Название группы" },
              region_ids: {
                type: "array", items: { type: "integer" },
                description: "ID регионов показа (225 = Россия, 1 = Москва и область, 2 = СПб и область)"
              },
              negative_keywords: { type: "array", items: { type: "string" }, description: "Минус-фразы группы" }
            },
            required: %w[campaign_id name region_ids]
          }
        ) do |client, args|
          group = {
            "Name" => args["name"],
            "CampaignId" => args["campaign_id"],
            "RegionIds" => args["region_ids"]
          }
          group["NegativeKeywords"] = { "Items" => args["negative_keywords"] } if args["negative_keywords"]

          client.call("adgroups", "add", { "AdGroups" => [group] })
        end

        registry.register(
          name: "yandex_direct_adgroups_update",
          description: "Обновить группу объявлений (название, регионы, минус-фразы).",
          input_schema: {
            type: "object",
            properties: {
              id: { type: "integer", description: "ID группы" },
              name: { type: "string", description: "Новое название" },
              region_ids: { type: "array", items: { type: "integer" }, description: "Новые регионы" },
              negative_keywords: { type: "array", items: { type: "string" }, description: "Минус-фразы" }
            },
            required: %w[id]
          }
        ) do |client, args|
          group = { "Id" => args["id"] }
          group["Name"] = args["name"] if args["name"]
          group["RegionIds"] = args["region_ids"] if args["region_ids"]
          group["NegativeKeywords"] = { "Items" => args["negative_keywords"] } if args["negative_keywords"]

          client.call("adgroups", "update", { "AdGroups" => [group] })
        end

        registry.register(
          name: "yandex_direct_adgroups_delete",
          description: "Удалить группы объявлений.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID групп для удаления" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("adgroups", "delete", { "SelectionCriteria" => { "Ids" => args["ids"] } })
        end
      end
    end
  end
end
