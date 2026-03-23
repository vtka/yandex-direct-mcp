# frozen_string_literal: true

module YandexDirectMcp
  module Tools
    module AdExtensions
      def self.register(registry)
        registry.register(
          name: "yandex_direct_callouts_add",
          description: "Создать уточнения (callouts) для объявлений. Каждое до 25 символов. " \
                       "Общая длина: до 132 символов на десктопе, 76 на мобильных. " \
                       "Возвращает ID для привязки к объявлению через AdExtensionIds.",
          input_schema: {
            type: "object",
            properties: {
              callouts: {
                type: "array",
                description: "Массив текстов уточнений",
                items: { type: "string" }
              }
            },
            required: %w[callouts]
          }
        ) do |client, args|
          extensions = args["callouts"].map do |text|
            { "Callout" => { "CalloutText" => text } }
          end

          client.call("adextensions", "add", { "AdExtensions" => extensions })
        end

        registry.register(
          name: "yandex_direct_callouts_get",
          description: "Получить уточнения по ID.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID уточнений" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("adextensions", "get", {
            "SelectionCriteria" => { "Ids" => args["ids"] },
            "FieldNames" => %w[Id Type Status],
            "CalloutFieldNames" => %w[CalloutText]
          })
        end
      end
    end
  end
end
