# frozen_string_literal: true

module YandexDirectMcp
  module Tools
    module Sitelinks
      def self.register(registry)
        registry.register(
          name: "yandex_direct_sitelinks_add",
          description: "Создать набор быстрых ссылок (1-8 шт). Каждая ссылка: title (до 30 символов), href, " \
                       "description (до 60 символов, опционально). Ссылки 1-4 суммарно до 66 символов, 5-8 тоже до 66. " \
                       "Возвращает SitelinkSetId для привязки к объявлению.",
          input_schema: {
            type: "object",
            properties: {
              sitelinks: {
                type: "array",
                description: "Массив быстрых ссылок (1-8)",
                items: {
                  type: "object",
                  properties: {
                    title: { type: "string", description: "Текст ссылки (до 30 символов)" },
                    href: { type: "string", description: "URL ссылки" },
                    description: { type: "string", description: "Описание (до 60 символов, опционально)" }
                  },
                  required: %w[title href]
                }
              }
            },
            required: %w[sitelinks]
          }
        ) do |client, args|
          links = args["sitelinks"].map do |sl|
            item = { "Title" => sl["title"], "Href" => sl["href"] }
            item["Description"] = sl["description"] if sl["description"]
            item
          end

          client.call("sitelinks", "add", {
            "SitelinksSets" => [{ "Sitelinks" => links }]
          })
        end

        registry.register(
          name: "yandex_direct_sitelinks_get",
          description: "Получить наборы быстрых ссылок по ID.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID наборов" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("sitelinks", "get", {
            "SelectionCriteria" => { "Ids" => args["ids"] },
            "FieldNames" => %w[Id Sitelinks]
          })
        end
      end
    end
  end
end
