# frozen_string_literal: true

module YandexDirectMcp
  module Tools
    module BidModifiers
      GENDER_VALUES = %w[GENDER_MALE GENDER_FEMALE].freeze
      AGE_VALUES = %w[AGE_0_17 AGE_18_24 AGE_25_34 AGE_35_44 AGE_45_54 AGE_55].freeze

      def self.register(registry)
        registry.register(
          name: "yandex_direct_bidmodifiers_demographics",
          description: "Установить корректировки ставок по полу и возрасту. " \
                       "BidModifier=0 отключает показы для сегмента, 50=снизить вдвое, 100=без изменений, 200=удвоить (макс 1300). " \
                       "Возрастные группы: AGE_0_17, AGE_18_24, AGE_25_34, AGE_35_44, AGE_45_54, AGE_55. " \
                       "Пол: GENDER_MALE, GENDER_FEMALE.",
          input_schema: {
            type: "object",
            properties: {
              campaign_id: { type: "integer", description: "ID кампании" },
              adjustments: {
                type: "array",
                description: "Массив корректировок",
                items: {
                  type: "object",
                  properties: {
                    gender: { type: "string", enum: GENDER_VALUES, description: "Пол (опционально)" },
                    age: { type: "string", enum: AGE_VALUES, description: "Возрастная группа (опционально)" },
                    bid_modifier: { type: "integer", description: "Коэффициент ставки в % (0=отключить, 100=без изменений)" }
                  },
                  required: %w[bid_modifier]
                }
              }
            },
            required: %w[campaign_id adjustments]
          }
        ) do |client, args|
          demographics = args["adjustments"].map do |adj|
            item = { "BidModifier" => adj["bid_modifier"] }
            item["Gender"] = adj["gender"] if adj["gender"]
            item["Age"] = adj["age"] if adj["age"]
            item
          end

          client.call("bidmodifiers", "add", {
            "BidModifiers" => [{
              "CampaignId" => args["campaign_id"],
              "DemographicsAdjustments" => demographics
            }]
          })
        end

        registry.register(
          name: "yandex_direct_bidmodifiers_get",
          description: "Получить корректировки ставок для кампании.",
          input_schema: {
            type: "object",
            properties: {
              campaign_ids: { type: "array", items: { type: "integer" }, description: "ID кампаний" }
            },
            required: %w[campaign_ids]
          }
        ) do |client, args|
          client.call("bidmodifiers", "get", {
            "SelectionCriteria" => { "CampaignIds" => args["campaign_ids"], "Levels" => %w[CAMPAIGN] },
            "FieldNames" => %w[Id CampaignId Type],
            "DemographicsAdjustmentFieldNames" => %w[Id Gender Age BidModifier]
          })
        end

        registry.register(
          name: "yandex_direct_bidmodifiers_set",
          description: "Обновить значение корректировки ставки по ID. Получить ID можно через bidmodifiers_get.",
          input_schema: {
            type: "object",
            properties: {
              adjustments: {
                type: "array",
                description: "Массив обновлений",
                items: {
                  type: "object",
                  properties: {
                    id: { type: "integer", description: "ID корректировки" },
                    bid_modifier: { type: "integer", description: "Новый коэффициент (0-1300)" }
                  },
                  required: %w[id bid_modifier]
                }
              }
            },
            required: %w[adjustments]
          }
        ) do |client, args|
          modifiers = args["adjustments"].map do |adj|
            { "Id" => adj["id"], "BidModifier" => adj["bid_modifier"] }
          end

          client.call("bidmodifiers", "set", { "BidModifiers" => modifiers })
        end
      end
    end
  end
end
