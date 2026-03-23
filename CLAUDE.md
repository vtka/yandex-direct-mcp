# CLAUDE.md — Yandex Direct MCP Server

## Project overview

MCP server for Yandex Direct API (JSON v5). Ruby-based, stdio transport.
Manages campaigns, ad groups, ads, keywords, images, bid modifiers, reports, and dictionaries.

## Architecture

- `lib/yandex_direct_mcp/client.rb` — HTTP client for Yandex Direct JSON API v5
- `lib/yandex_direct_mcp/server.rb` — MCP server (stdio JSON-RPC)
- `lib/yandex_direct_mcp/tool_registry.rb` — tool registration DSL
- `lib/yandex_direct_mcp/tools/` — one file per API service (campaigns, ads, ad_images, etc.)
- `lib/yandex_direct_mcp.rb` — requires all modules (must add new tools here too)

## Adding a new tool

1. Create `lib/yandex_direct_mcp/tools/<name>.rb` with a `register(registry)` method
2. Add `require_relative` in `lib/yandex_direct_mcp.rb`
3. Add `Tools::<Name>.register(@registry)` in `server.rb#register_all_tools`
4. Restart MCP (`/mcp` in Claude Code) to pick up changes

## Yandex Direct API gotchas

### Budget & currency
- Account currency is **KZT (tenge)**, not rubles
- API returns budgets in **microcurrency** (1 tenge = 1,000,000 micro). Divide by 1,000,000 to display
- Minimum daily budget is **1,300 tenge**. Weekly budget is not supported — divide by 7 and use daily
- The `daily_budget` tool parameter accepts plain tenge (auto-converted to micro internally)

### Images (AdImages service)
- Images must be uploaded first via `adimages/add` (base64), which returns `AdImageHash`
- Then attach hash to ad via `AdImageHash` field in TextAd
- Image types: REGULAR (square, min 450×450), WIDE (16:9, min 1080×607)
- Book covers are typically vertical — must crop/resize before upload
- Use `sips` on macOS for cropping (available in the tool with `crop` parameter)
- When cropping vertical images to square, offset ~30% from top preserves title + characters

### Demographic bid modifiers (BidModifiers service)
- Max **12 adjustments** per campaign
- Every adjustment must specify **both** `Gender` AND `Age` to avoid overlap errors (code 6000)
- Don't mix "gender-only" and "age-only" adjustments — they intersect and API rejects the whole batch
- `BidModifier=0` disables the segment, `100`=no change, `200`=double the bid (max 1300)
- Age enums: AGE_0_17, AGE_18_24, AGE_25_34, AGE_35_44, AGE_45_54, AGE_55
- Gender enums: GENDER_MALE, GENDER_FEMALE

### Ads
- Title: max 56 chars, Title2: max 30 chars, Text: max 81 chars
- For 18+ content: include "18+" in ad text (required by law), add negative keywords for children's content
- After creating/updating ads, they need moderation (`ads/moderate`)

### Regions
- Standard Russian-speaking set: 225 (Russia), 149 (Belarus), 159 (Kazakhstan), 977
- Region IDs come from `dictionaries/get` with `GeoRegions`

### Keywords
- `---autotargeting` is a special system keyword, don't touch it
- Adapt keywords to the book's actual genre — don't reuse detective keywords for romance, etc.

## Campaign creation checklist

1. Create campaign (name, start_date, daily_budget)
2. Create ad group (campaign_id, name, region_ids)
3. Upload image if needed (adimages_add with crop)
4. Create ad (title, text, href, ad_image_hash)
5. Add keywords adapted to content genre
6. Add negative keywords (e.g., children's content for 18+ ads)
7. Set demographic bid modifiers if targeting specific audience
8. Send to moderation when ready
