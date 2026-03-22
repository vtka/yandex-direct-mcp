# frozen_string_literal: true

module YandexDirectMcp
  module Tools
    module Dictionaries
      def self.register(registry)
        registry.register(
          name: "yandex_direct_dictionaries_regions",
          description: "Получить справочник регионов (гео-таргетинг). " \
                       "Возвращает ID, название и тип региона (страна, область, город).",
          input_schema: {
            type: "object",
            properties: {}
          }
        ) do |client, _args|
          client.call("dictionaries", "get", { "DictionaryNames" => ["GeoRegions"] })
        end

        registry.register(
          name: "yandex_direct_dictionaries_currencies",
          description: "Получить справочник валют с минимальными и максимальными значениями ставок.",
          input_schema: {
            type: "object",
            properties: {}
          }
        ) do |client, _args|
          client.call("dictionaries", "get", { "DictionaryNames" => ["Currencies"] })
        end

        registry.register(
          name: "yandex_direct_dictionaries_interests",
          description: "Получить справочник интересов аудитории для таргетинга.",
          input_schema: {
            type: "object",
            properties: {}
          }
        ) do |client, _args|
          client.call("dictionaries", "get", { "DictionaryNames" => %w[Interests AudienceInterests] })
        end

        registry.register(
          name: "yandex_direct_dictionaries_all",
          description: "Получить все справочники сразу (регионы, валюты, часовые пояса, интересы и др.).",
          input_schema: {
            type: "object",
            properties: {
              names: {
                type: "array",
                items: {
                  type: "string",
                  enum: %w[Currencies GeoRegions TimeZones Constants AdCategories
                           Interests AudienceInterests AudienceDemographicProfiles]
                },
                description: "Какие справочники загрузить (по умолч. все)"
              }
            }
          }
        ) do |client, args|
          names = args["names"] || %w[Currencies GeoRegions TimeZones Constants]
          client.call("dictionaries", "get", { "DictionaryNames" => names })
        end
      end
    end
  end
end
