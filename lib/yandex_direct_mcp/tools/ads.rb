# frozen_string_literal: true

module YandexDirectMcp
  module Tools
    module Ads
      def self.register(registry)
        registry.register(
          name: "yandex_direct_ads_get",
          description: "Получить объявления. Фильтр по ID кампании, группы или конкретным ID объявлений.",
          input_schema: {
            type: "object",
            properties: {
              campaign_ids: { type: "array", items: { type: "integer" }, description: "ID кампаний" },
              ad_group_ids: { type: "array", items: { type: "integer" }, description: "ID групп" },
              ids: { type: "array", items: { type: "integer" }, description: "ID объявлений" },
              limit: { type: "integer", description: "Макс. кол-во (по умолч. 100)", default: 100 }
            }
          }
        ) do |client, args|
          criteria = {}
          criteria["CampaignIds"] = args["campaign_ids"] if args["campaign_ids"]
          criteria["AdGroupIds"] = args["ad_group_ids"] if args["ad_group_ids"]
          criteria["Ids"] = args["ids"] if args["ids"]

          client.call("ads", "get", {
            "SelectionCriteria" => criteria,
            "FieldNames" => %w[Id CampaignId AdGroupId Type State Status],
            "TextAdFieldNames" => %w[Title Title2 Text Href DisplayDomain Mobile],
            "Page" => { "Limit" => args["limit"] || 100 }
          })
        end

        registry.register(
          name: "yandex_direct_ads_add",
          description: "Создать текстово-графическое объявление. Укажите заголовок (до 56 символов), " \
                       "текст (до 81 символа), ссылку и ID группы.",
          input_schema: {
            type: "object",
            properties: {
              ad_group_id: { type: "integer", description: "ID группы объявлений" },
              title: { type: "string", description: "Заголовок (до 56 символов)" },
              title2: { type: "string", description: "Второй заголовок (до 30 символов, опционально)" },
              text: { type: "string", description: "Текст объявления (до 81 символа)" },
              href: { type: "string", description: "Ссылка на сайт" },
              mobile: { type: "string", enum: %w[YES NO], description: "Мобильное объявление (YES/NO)", default: "NO" },
              ad_image_hash: { type: "string", description: "Хеш изображения (получить через yandex_direct_adimages_add)" },
              sitelink_set_id: { type: "integer", description: "ID набора быстрых ссылок (получить через yandex_direct_sitelinks_add)" },
              ad_extension_ids: { type: "array", items: { type: "integer" }, description: "ID уточнений (получить через yandex_direct_callouts_add)" }
            },
            required: %w[ad_group_id title text href]
          }
        ) do |client, args|
          ad = {
            "AdGroupId" => args["ad_group_id"],
            "TextAd" => {
              "Title" => args["title"],
              "Text" => args["text"],
              "Href" => args["href"],
              "Mobile" => args["mobile"] || "NO"
            }
          }
          ad["TextAd"]["Title2"] = args["title2"] if args["title2"]
          ad["TextAd"]["AdImageHash"] = args["ad_image_hash"] if args["ad_image_hash"]
          ad["TextAd"]["SitelinkSetId"] = args["sitelink_set_id"] if args["sitelink_set_id"]
          ad["TextAd"]["AdExtensionIds"] = args["ad_extension_ids"] if args["ad_extension_ids"]

          client.call("ads", "add", { "Ads" => [ad] })
        end

        registry.register(
          name: "yandex_direct_ads_update",
          description: "Обновить объявление (заголовок, текст, ссылку).",
          input_schema: {
            type: "object",
            properties: {
              id: { type: "integer", description: "ID объявления" },
              title: { type: "string", description: "Новый заголовок" },
              title2: { type: "string", description: "Новый второй заголовок" },
              text: { type: "string", description: "Новый текст" },
              href: { type: "string", description: "Новая ссылка" },
              ad_image_hash: { type: "string", description: "Хеш изображения" },
              sitelink_set_id: { type: "integer", description: "ID набора быстрых ссылок" },
              ad_extension_ids: { type: "array", items: { type: "integer" }, description: "ID уточнений" }
            },
            required: %w[id]
          }
        ) do |client, args|
          text_ad = {}
          text_ad["Title"] = args["title"] if args["title"]
          text_ad["Title2"] = args["title2"] if args["title2"]
          text_ad["Text"] = args["text"] if args["text"]
          text_ad["Href"] = args["href"] if args["href"]
          text_ad["AdImageHash"] = args["ad_image_hash"] if args["ad_image_hash"]
          text_ad["SitelinkSetId"] = args["sitelink_set_id"] if args["sitelink_set_id"]

          ad = { "Id" => args["id"], "TextAd" => text_ad }
          ad["AdExtensionIds"] = args["ad_extension_ids"] if args["ad_extension_ids"]

          client.call("ads", "update", { "Ads" => [ad] })
        end

        registry.register(
          name: "yandex_direct_ads_delete",
          description: "Удалить объявления.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID объявлений" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("ads", "delete", { "SelectionCriteria" => { "Ids" => args["ids"] } })
        end

        registry.register(
          name: "yandex_direct_ads_suspend",
          description: "Остановить показы объявлений.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID объявлений" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("ads", "suspend", { "SelectionCriteria" => { "Ids" => args["ids"] } })
        end

        registry.register(
          name: "yandex_direct_ads_resume",
          description: "Возобновить показы объявлений.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID объявлений" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("ads", "resume", { "SelectionCriteria" => { "Ids" => args["ids"] } })
        end

        registry.register(
          name: "yandex_direct_ads_moderate",
          description: "Отправить объявления на модерацию.",
          input_schema: {
            type: "object",
            properties: {
              ids: { type: "array", items: { type: "integer" }, description: "ID объявлений" }
            },
            required: %w[ids]
          }
        ) do |client, args|
          client.call("ads", "moderate", { "SelectionCriteria" => { "Ids" => args["ids"] } })
        end
      end
    end
  end
end
