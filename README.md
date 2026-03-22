# yandex-direct-mcp

MCP server for managing Yandex Direct ad campaigns via AI assistants (Claude Code, Claude Desktop, ChatGPT, etc.).

Pure Ruby, no external dependencies. 30 tools for a complete advertising workflow: creating campaigns, writing ads, selecting keywords, analytics.

## Features

| Service | Tools | Description |
|---|---|---|
| **Campaigns** | 6 | Create, edit, suspend, resume, delete campaigns |
| **Ad Groups** | 4 | Ad groups with geo-targeting and negative keywords |
| **Ads** | 7 | Text & image ads, moderation |
| **Keywords** | 6 | Keywords, bids, suspend/resume |
| **Reports** | 3 | Reports on campaigns, ads, search queries |
| **Dictionaries** | 4 | Dictionaries for regions, currencies, audience interests |

## Quick Start

### 1. Create an OAuth Application

1. Go to [oauth.yandex.ru](https://oauth.yandex.ru/) and create a new application
2. Platform type: **Web services**
3. Redirect URI: `https://oauth.yandex.ru/verification_code`
4. Permissions: **Yandex.Direct — Use Yandex.Direct API**

### 2. Confirm API Access

After creating the OAuth application, you need to submit a request for full access to the Yandex Direct API:

1. Sign in to [Yandex Direct](https://direct.yandex.ru/)
2. Go to **Tools → API** (or use the direct link: `https://direct.yandex.ru/registered/main.pl?cmd=apiSettings`)
3. Open the **"My requests"** tab → **"New request"**
4. Fill out the form:
   - **Application:** select your OAuth application from the list
   - **Contact:** your email
   - **Type of work:** "Direct advertiser automating management of own campaigns"
   - **Programming language:** Ruby
   - **Protocol:** JSON
   - **Logins:** your Yandex Direct login
5. Submit the request — the API starts working immediately after submission (status "new")

> **Without this step, the API will return an "Incomplete registration" error (code 58).**

### 3. Obtain an OAuth Token

Open the following URL in your browser (replace with your Client ID):

```
https://oauth.yandex.ru/authorize?response_type=token&client_id=YOUR_CLIENT_ID
```

Sign in and copy the token from the address bar.

### 4. Connect to Claude Code

Add the following to your project's `.mcp.json`:

```json
{
  "mcpServers": {
    "yandex-direct": {
      "command": "ruby",
      "args": ["/path/to/yandex-direct-mcp/bin/server"],
      "env": {
        "YANDEX_DIRECT_TOKEN": "your_oauth_token"
      }
    }
  }
}
```

Or add it to the global config `~/.claude.json` (under the `mcpServers` section) to make the server available across all projects.

For **Claude Desktop** — add the same configuration to `~/Library/Application Support/Claude/claude_desktop_config.json`.

### 5. Start Using It

Once connected, the AI assistant will have access to all 30 tools and will be able to manage your campaigns via chat:

- *"Show my campaigns"*
- *"Create a campaign to promote a book with a budget of 500 RUB/day"*
- *"Add keywords: read online, new books 2026"*
- *"Show statistics for the last week"*
- *"What search queries are bringing customers?"*
- *"Pause the campaign"*
- *"Update the ad text"*

> **Note:** The budget currency is determined by the Yandex Direct account (rubles, tenge, etc.). The `daily_budget` parameter specifies the amount in the account's primary currency.

## Limitations

- **SMB campaigns** (created via the simplified Yandex Direct wizard) are not visible through the API — only TEXT_CAMPAIGN type campaigns
- **Callouts** can be created via the API, but can only be linked to an ad through the web interface
- **Images** can only be uploaded via URL or base64 — local files must first be hosted or encoded
- Yandex requires a **landscape image** (minimum 1080x607) for text & image ads

## Sandbox Mode

For testing without real expenses, add the `YANDEX_DIRECT_SANDBOX` environment variable:

```json
{
  "mcpServers": {
    "yandex-direct": {
      "command": "ruby",
      "args": ["/path/to/yandex-direct-mcp/bin/server"],
      "env": {
        "YANDEX_DIRECT_TOKEN": "your_token",
        "YANDEX_DIRECT_SANDBOX": "true"
      }
    }
  }
}
```

Sandbox uses the Yandex Direct test API — all operations are performed on fictitious data.

## Tool List

### Campaigns

| Tool | Description |
|---|---|
| `yandex_direct_campaigns_get` | Get a list of campaigns with filtering by ID, state, type |
| `yandex_direct_campaigns_add` | Create a campaign with name, start date, budget, negative keywords |
| `yandex_direct_campaigns_update` | Update campaign parameters |
| `yandex_direct_campaigns_delete` | Delete (archive) campaigns |
| `yandex_direct_campaigns_suspend` | Suspend impressions |
| `yandex_direct_campaigns_resume` | Resume impressions |

### Ad Groups

| Tool | Description |
|---|---|
| `yandex_direct_adgroups_get` | Get groups by campaign ID or group ID |
| `yandex_direct_adgroups_add` | Create a group with name, regions, and negative keywords |
| `yandex_direct_adgroups_update` | Update a group |
| `yandex_direct_adgroups_delete` | Delete groups |

### Ads

| Tool | Description |
|---|---|
| `yandex_direct_ads_get` | Get ads with filtering |
| `yandex_direct_ads_add` | Create a text & image ad (title, text, link) |
| `yandex_direct_ads_update` | Update an ad |
| `yandex_direct_ads_delete` | Delete ads |
| `yandex_direct_ads_suspend` | Suspend ad impressions |
| `yandex_direct_ads_resume` | Resume impressions |
| `yandex_direct_ads_moderate` | Submit for moderation |

### Keywords

| Tool | Description |
|---|---|
| `yandex_direct_keywords_get` | Get keywords by campaign or group |
| `yandex_direct_keywords_add` | Add keywords to ad groups |
| `yandex_direct_keywords_update` | Update keyword text |
| `yandex_direct_keywords_delete` | Delete keywords |
| `yandex_direct_keywords_suspend` | Suspend impressions for keywords |
| `yandex_direct_keywords_resume` | Resume impressions |

### Reports

| Tool | Description |
|---|---|
| `yandex_direct_report_campaign` | Campaign statistics: impressions, clicks, cost, CTR, CPC |
| `yandex_direct_report_ad` | Statistics by ad |
| `yandex_direct_report_search_queries` | User search queries (for finding negative keywords) |

### Dictionaries

| Tool | Description |
|---|---|
| `yandex_direct_dictionaries_regions` | Regions for geo-targeting (ID, name, type) |
| `yandex_direct_dictionaries_currencies` | Currencies and bid limits |
| `yandex_direct_dictionaries_interests` | Audience interests for targeting |
| `yandex_direct_dictionaries_all` | All dictionaries at once |

## Project Structure

```
yandex-direct-mcp/
├── bin/server                          # MCP server entry point
├── lib/
│   ├── yandex_direct_mcp.rb            # Module loader
│   └── yandex_direct_mcp/
│       ├── client.rb                   # HTTP client for Yandex Direct API v5
│       ├── server.rb                   # MCP JSON-RPC protocol (stdio)
│       ├── tool_registry.rb            # Tool registry
│       └── tools/
│           ├── campaigns.rb            # Campaign management
│           ├── ad_groups.rb            # Ad groups
│           ├── ads.rb                  # Ads
│           ├── keywords.rb             # Keywords
│           ├── reports.rb              # Analytics and reports
│           └── dictionaries.rb         # Dictionaries
├── Gemfile
├── LICENSE
└── .gitignore
```

## Requirements

- Ruby >= 3.1
- Yandex Direct API OAuth token (free)

## License

MIT
