# yandex-direct-mcp

MCP-сервер для управления рекламными кампаниями Яндекс Директ через AI-ассистентов (Claude, ChatGPT и др.).

Чистый Ruby, без внешних зависимостей. 30 инструментов для полного цикла работы с рекламой: создание кампаний, написание объявлений, подбор ключевых фраз, аналитика.

## Возможности

| Сервис | Инструменты | Описание |
|---|---|---|
| **Campaigns** | 6 | Создание, редактирование, остановка, возобновление, удаление кампаний |
| **Ad Groups** | 4 | Группы объявлений с гео-таргетингом и минус-фразами |
| **Ads** | 7 | Текстово-графические объявления, модерация |
| **Keywords** | 6 | Ключевые фразы, ставки, остановка/возобновление |
| **Reports** | 3 | Отчёты по кампаниям, объявлениям, поисковым запросам |
| **Dictionaries** | 4 | Справочники регионов, валют, интересов аудитории |

## Быстрый старт

### 1. Получите OAuth-токен Яндекса

1. Перейдите на [oauth.yandex.ru](https://oauth.yandex.ru/) и создайте приложение
2. Тип платформы: **Веб-сервисы**
3. Права доступа: **Яндекс.Директ — Использование API Яндекс.Директа**
4. Получите токен, перейдя по ссылке:
   ```
   https://oauth.yandex.ru/authorize?response_type=token&client_id=ВАШ_CLIENT_ID
   ```

### 2. Подключите к Claude Code

Добавьте в `.mcp.json` вашего проекта:

```json
{
  "mcpServers": {
    "yandex-direct": {
      "command": "ruby",
      "args": ["/путь/к/yandex-direct-mcp/bin/server"],
      "env": {
        "YANDEX_DIRECT_TOKEN": "ваш_oauth_токен"
      }
    }
  }
}
```

Или в глобальный `~/.claude.json`:

```json
{
  "mcpServers": {
    "yandex-direct": {
      "command": "ruby",
      "args": ["/путь/к/yandex-direct-mcp/bin/server"],
      "env": {
        "YANDEX_DIRECT_TOKEN": "ваш_oauth_токен"
      }
    }
  }
}
```

### 3. Используйте

После подключения AI-ассистент получит доступ ко всем 30 инструментам и сможет управлять вашими кампаниями через чат:

- *«Покажи мои кампании»*
- *«Создай кампанию для продвижения книги с бюджетом 500 руб/день»*
- *«Добавь ключевые фразы: читать онлайн, новые книги 2026»*
- *«Покажи статистику за последнюю неделю»*
- *«Какие поисковые запросы приводят клиентов?»*

## Sandbox-режим

Для тестирования без реальных расходов установите переменную окружения:

```json
{
  "env": {
    "YANDEX_DIRECT_TOKEN": "ваш_токен",
    "YANDEX_DIRECT_SANDBOX": "true"
  }
}
```

Sandbox использует тестовый API Яндекс Директа — все операции выполняются на фиктивных данных.

## Список инструментов

### Кампании

| Инструмент | Описание |
|---|---|
| `yandex_direct_campaigns_get` | Получить список кампаний с фильтрацией по ID, состоянию, типу |
| `yandex_direct_campaigns_add` | Создать кампанию с названием, датой старта, бюджетом, минус-фразами |
| `yandex_direct_campaigns_update` | Обновить параметры кампании |
| `yandex_direct_campaigns_delete` | Удалить (архивировать) кампании |
| `yandex_direct_campaigns_suspend` | Остановить показы |
| `yandex_direct_campaigns_resume` | Возобновить показы |

### Группы объявлений

| Инструмент | Описание |
|---|---|
| `yandex_direct_adgroups_get` | Получить группы по ID кампании или группы |
| `yandex_direct_adgroups_add` | Создать группу с названием, регионами и минус-фразами |
| `yandex_direct_adgroups_update` | Обновить группу |
| `yandex_direct_adgroups_delete` | Удалить группы |

### Объявления

| Инструмент | Описание |
|---|---|
| `yandex_direct_ads_get` | Получить объявления с фильтрацией |
| `yandex_direct_ads_add` | Создать текстово-графическое объявление (заголовок, текст, ссылка) |
| `yandex_direct_ads_update` | Обновить объявление |
| `yandex_direct_ads_delete` | Удалить объявления |
| `yandex_direct_ads_suspend` | Остановить показы объявлений |
| `yandex_direct_ads_resume` | Возобновить показы |
| `yandex_direct_ads_moderate` | Отправить на модерацию |

### Ключевые фразы

| Инструмент | Описание |
|---|---|
| `yandex_direct_keywords_get` | Получить фразы по кампании или группе |
| `yandex_direct_keywords_add` | Добавить фразы в группы объявлений |
| `yandex_direct_keywords_update` | Обновить текст фраз |
| `yandex_direct_keywords_delete` | Удалить фразы |
| `yandex_direct_keywords_suspend` | Остановить показы по фразам |
| `yandex_direct_keywords_resume` | Возобновить показы |

### Отчёты

| Инструмент | Описание |
|---|---|
| `yandex_direct_report_campaign` | Статистика кампаний: показы, клики, расходы, CTR, CPC |
| `yandex_direct_report_ad` | Статистика по объявлениям |
| `yandex_direct_report_search_queries` | Поисковые запросы пользователей (для поиска минус-слов) |

### Справочники

| Инструмент | Описание |
|---|---|
| `yandex_direct_dictionaries_regions` | Регионы для гео-таргетинга (ID, название, тип) |
| `yandex_direct_dictionaries_currencies` | Валюты и лимиты ставок |
| `yandex_direct_dictionaries_interests` | Интересы аудитории для таргетинга |
| `yandex_direct_dictionaries_all` | Все справочники сразу |

## Структура проекта

```
yandex-direct-mcp/
├── bin/server                          # Точка входа MCP-сервера
├── lib/
│   ├── yandex_direct_mcp.rb            # Загрузка модулей
│   └── yandex_direct_mcp/
│       ├── client.rb                   # HTTP-клиент для Yandex Direct API v5
│       ├── server.rb                   # MCP JSON-RPC протокол (stdio)
│       ├── tool_registry.rb            # Реестр инструментов
│       └── tools/
│           ├── campaigns.rb            # Управление кампаниями
│           ├── ad_groups.rb            # Группы объявлений
│           ├── ads.rb                  # Объявления
│           ├── keywords.rb             # Ключевые фразы
│           ├── reports.rb              # Аналитика и отчёты
│           └── dictionaries.rb         # Справочники
├── Gemfile
└── .gitignore
```

## Требования

- Ruby >= 3.1
- OAuth-токен Яндекс Директ API

## Лицензия

MIT
