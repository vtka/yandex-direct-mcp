# frozen_string_literal: true

require "base64"
require "open3"
require "tmpdir"

module YandexDirectMcp
  module Tools
    module AdImages
      CROP_MODES = {
        "square" => { min: 450, ratio: [1, 1] },
        "wide" => { min_w: 1080, min_h: 607, ratio: [16, 9] }
      }.freeze

      def self.register(registry)
        registry.register(
          name: "yandex_direct_adimages_add",
          description: "Загрузить изображение для объявления. Укажите путь к файлу (PNG/JPG/GIF). " \
                       "Можно автоматически обрезать: crop=square (450x450, 1:1) или crop=wide (1080x607, 16:9). " \
                       "crop_offset сдвигает область обрезки (0=верх, 50=центр, 100=низ). " \
                       "Возвращает AdImageHash для использования в объявлениях.",
          input_schema: {
            type: "object",
            properties: {
              file_path: { type: "string", description: "Абсолютный путь к файлу изображения" },
              name: { type: "string", description: "Имя изображения (до 255 символов)" },
              crop: { type: "string", enum: %w[square wide], description: "Режим обрезки: square (1:1, мин. 450x450) или wide (16:9, мин. 1080x607)" },
              crop_offset: { type: "integer", description: "Смещение обрезки в % (0=верх, 50=центр, 100=низ). По умолчанию 50", default: 50 }
            },
            required: %w[file_path name]
          }
        ) do |client, args|
          file_path = args["file_path"]
          raise "Файл не найден: #{file_path}" unless File.exist?(file_path)

          upload_path = if args["crop"]
                          crop_image(file_path, args["crop"], args["crop_offset"] || 50)
                        else
                          file_path
                        end

          image_data = Base64.strict_encode64(File.binread(upload_path))

          result = client.call("adimages", "add", {
            "AdImages" => [{
              "ImageData" => image_data,
              "Name" => args["name"]
            }]
          })

          File.delete(upload_path) if upload_path != file_path && File.exist?(upload_path)

          result
        end

        registry.register(
          name: "yandex_direct_adimages_get",
          description: "Получить список загруженных изображений. Можно фильтровать по хешам.",
          input_schema: {
            type: "object",
            properties: {
              ad_image_hashes: { type: "array", items: { type: "string" }, description: "Хеши изображений" },
              limit: { type: "integer", description: "Макс. кол-во (по умолч. 50)", default: 50 }
            }
          }
        ) do |client, args|
          criteria = {}
          criteria["AdImageHashes"] = args["ad_image_hashes"] if args["ad_image_hashes"]

          client.call("adimages", "get", {
            "SelectionCriteria" => criteria,
            "FieldNames" => %w[AdImageHash Name Type Associated],
            "Page" => { "Limit" => args["limit"] || 50 }
          })
        end
      end

      def self.crop_image(file_path, mode, offset_pct)
        w, h = image_dimensions(file_path)
        config = CROP_MODES[mode]

        case mode
        when "square"
          side = [w, h].min
          target = [config[:min], side].max
          crop_w = crop_h = [side, w, h].min
        when "wide"
          rw, rh = config[:ratio]
          # Fit the widest possible 16:9 area
          if w.to_f / h > rw.to_f / rh
            crop_h = h
            crop_w = (h * rw.to_f / rh).to_i
          else
            crop_w = w
            crop_h = (w * rh.to_f / rw).to_i
          end
        end

        # Calculate vertical offset
        max_y = [h - crop_h, 0].max
        y_offset = (max_y * offset_pct / 100.0).to_i
        max_x = [w - crop_w, 0].max
        x_offset = (max_x * 0.5).to_i # always center horizontally

        tmp_path = File.join(Dir.tmpdir, "yd_crop_#{Process.pid}_#{Time.now.to_i}.png")
        FileUtils.cp(file_path, tmp_path)

        # Crop
        sips("--cropToHeightWidth", crop_h.to_s, crop_w.to_s,
             "--cropOffset", y_offset.to_s, x_offset.to_s, tmp_path)

        # Scale up if needed
        final_w, final_h = image_dimensions(tmp_path)
        case mode
        when "square"
          if final_w < config[:min]
            sips("--resampleWidth", config[:min].to_s, tmp_path)
          end
        when "wide"
          if final_w < config[:min_w]
            sips("--resampleWidth", config[:min_w].to_s, tmp_path)
          end
        end

        tmp_path
      end

      def self.image_dimensions(path)
        out, = Open3.capture2("sips", "-g", "pixelWidth", "-g", "pixelHeight", path)
        w = out[/pixelWidth:\s*(\d+)/, 1].to_i
        h = out[/pixelHeight:\s*(\d+)/, 1].to_i
        [w, h]
      end

      def self.sips(*args)
        out, err, status = Open3.capture3("sips", *args)
        raise "sips failed: #{err}" unless status.success?
        out
      end
    end
  end
end
