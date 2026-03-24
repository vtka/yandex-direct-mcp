# CLAUDE.md — Yandex Direct MCP Server

## Project overview

MCP server for Yandex Direct API (JSON v5). Ruby-based, stdio transport.
Manages campaigns, ad groups, ads, keywords, images, bid modifiers, sitelinks, callouts, reports, and dictionaries.

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
- Max **12 adjustments** per campaign (6 age groups × 2 genders = 12, exactly the limit)
- Every adjustment must specify **both** `Gender` AND `Age` to avoid overlap errors (code 6000)
- Don't mix "gender-only" and "age-only" adjustments — they intersect and API rejects the whole batch
- `BidModifier=0` disables the segment, `100`=no change, `200`=double the bid (max 1300)
- To update existing adjustments, use `bidmodifiers/set` with adjustment IDs (get IDs via `bidmodifiers/get`)
- `bidmodifiers/get` requires `Levels` parameter in SelectionCriteria (e.g., `["CAMPAIGN"]`), otherwise error 8000
- Age enums: AGE_0_17, AGE_18_24, AGE_25_34, AGE_35_44, AGE_45_54, AGE_55
- Gender enums: GENDER_MALE, GENDER_FEMALE

### Sitelinks (быстрые ссылки)
- Create a set of 1-8 sitelinks via `sitelinks/add`, returns `SitelinkSetId`
- Each sitelink: Title (max 30 chars), Href, Description (max 60 chars, optional)
- Links 1-4: total max **66 characters** in titles. Links 5-8: same limit
- Attach to ad via `SitelinkSetId` field in TextAd
- **Always add sitelinks** — Yandex warns "ad may perform poorly" without them

### Callouts / Ad Extensions (уточнения)
- Create callouts via `adextensions/add`, returns IDs
- Each callout: max **25 characters**
- Total length: max 132 chars on desktop, 76 on mobile
- Attach to ad via `AdExtensionIds` array **inside TextAd** (up to 50 IDs)
- **Cannot add callouts via `ads/update`** — TextAdUpdate doesn't support AdExtensionIds. Must delete and recreate the ad
- **Always add callouts** — Yandex warns "ad may perform poorly" without them

### Ads
- Title: max 56 chars, Title2: max 30 chars, Text: max 81 chars
- For 18+ content: include "18+" in ad text (required by law), add negative keywords for children's content
- After creating/updating ads, they need moderation (`ads/moderate`)
- Ad quality checklist: image + sitelinks + callouts = good quality score. Missing any = warning

### Regions
- Standard Russian-speaking set: 225 (Russia), 149 (Belarus), 159 (Kazakhstan), 977
- Region IDs come from `dictionaries/get` with `GeoRegions`

### Keywords & Bids
- `---autotargeting` is a special system keyword, don't touch it
- Adapt keywords to the book's actual genre — don't reuse detective keywords for romance, etc.
- Avoid generic keywords that attract wrong audience (e.g., "электронная книга купить" brings e-reader buyers)
- **Bids are set via `keywordbids` service**, NOT via `keywords/update` (which only changes text)
- `keywordbids/set` accepts `KeywordId`, `SearchBid`, `NetworkBid` — values in **microcurrency**
- Default bid of 1 tenge is too low for any impressions — set at least 20-50 tenge for books niche

### Monitoring (separate repo: vtka/yandex-direct-monitoring)
- GitHub Actions sends daily/weekly reports to Telegram via bot
- Currency symbol fetched dynamically from Yandex API (`clients/get` → Currency field)
- Campaign names cleaned from domain suffixes to prevent Telegram auto-linking

## Campaign creation checklist (MANDATORY)

Every new campaign MUST follow ALL these steps. Skipping any step results in poor ad quality or wasted budget.

### 1. Create campaign
- `campaigns_add` with name, start_date, daily_budget
- Budget: minimum 1,300 tenge/day. If user asks for weekly budget, divide by 7

### 2. Create ad group
- `adgroups_add` with campaign_id, name, region_ids
- Default regions: `[225, 149, 159, 977]` (Russia, Belarus, Kazakhstan)

### 3. Upload image
- `adimages_add` with file_path, name, crop parameter
- Book covers are vertical — use `crop=square` with `crop_offset=30` to capture title + art
- MUST crop/resize — raw vertical covers will be rejected (min 450×450)

### 4. Create sitelinks
- `sitelinks_add` with 4 relevant links (e.g., "Читать онлайн", "Все книги автора", genre page, platform page)
- Each title max 30 chars, links 1-4 total max 66 chars
- WITHOUT sitelinks the ad gets "may perform poorly" warning (red quality bar)

### 5. Create callouts
- `callouts_add` with 4 short phrases (e.g., "Бесплатно онлайн", "Новинка 2026", genre tag)
- Each max 25 chars
- WITHOUT callouts the ad gets "may perform poorly" warning (red quality bar)

### 6. Create ad (with ALL attachments)
- `ads_add` with title, title2, text, href, ad_image_hash, sitelink_set_id, ad_extension_ids
- ALL attachments must be set at creation — callouts (AdExtensionIds) CANNOT be added later via update
- If you need to add callouts to existing ad: delete it and recreate with all fields
- For 18+ content: include "18+" in ad text (required by law)

### 7. Add keywords
- `keywords_add` — adapt to the book's actual genre, don't copy from other campaigns
- Include: genre-specific terms, platform name, book title, author-related queries
- Exclude misleading generic keywords

### 8. Add negative keywords
- `campaigns_update` with negative_keywords
- For 18+ content: add children-related negative keywords (детские книги, книги для детей, etc.)

### 9. Set keyword bids (CPC)
- `keywords_set_bids` — set competitive bids for all keywords INCLUDING autotargeting
- **Default 1 tenge bid = zero impressions.** Must set 10-50 tenge depending on niche
- Books niche: 10-30 tenge is a reasonable starting point
- Bids are in **microcurrency** (10 tenge = 10,000,000)

### 10. Set demographic targeting
- `bidmodifiers_demographics` — set ALL 12 gender×age combinations to avoid overlap errors
- Boost target audience (e.g., women 25-44 → BidModifier 200)
- Lower non-target (e.g., men → BidModifier 10)
- Disable under-17 (BidModifier 0) for 18+ content
- Must specify BOTH gender AND age in every adjustment

### 11. Verify campaign quality
- Check ad status via `ads_get` — should be ACCEPTED after moderation
- Check campaign state via `campaigns_get` — should be ON
- Verify: image attached, sitelinks attached, callouts attached, bids set above minimum
- All these together = green quality bar in Yandex Direct UI

### 12. Send to moderation
- `ads_moderate` when everything is ready
- Moderation takes 1-3 days for new campaigns
