# kalopilot-skill

A Claude skill for querying TikTok e-commerce data through [KaloPilot](https://kalodata.com) — an AI-powered TikTok Shop analytics agent.

## What it does

Ask questions about TikTok Shop data in natural language. The skill routes your queries to KaloPilot's AI agent, which has access to 20+ data tools covering:

- **Products** — rankings, sales trends, price analysis, breakout products
- **Shops** — store rankings, revenue, product mix, growth metrics
- **Creators** — performance, GMV, follower analysis, collaboration data
- **Videos** — viral product videos, engagement, conversion analysis
- **Livestreams** — live sales, viewer metrics, product performance
- **Categories** — market size, growth trends, competition landscape

Supports all TikTok Shop regions: US, UK, ID, TH, VN, PH, MY, SG, MX, BR, JP, and more.

## Installation

```bash
npx skills add https://github.com/sailtonight/kalopilot-skill --skill kalopilot
```

## Setup

You need a KaloData account with API access.

**Where to find your token:** go to [kalodata.com/pilot](https://kalodata.com/pilot), click **Connect OpenClaw** in the bottom-left of the sidebar, and copy the string under **Current Account Token** in the dialog that opens.

On first use, the skill will walk you through this and save the token for you. You don't need to do anything manually.

To set it up by hand instead:

```bash
mkdir -p ~/.kalopilot
echo -n "your-token-here" > ~/.kalopilot/token
chmod 600 ~/.kalopilot/token
```

## Usage

Just ask about TikTok data:

```
> What are the top-selling products in the US this week?
> Which creators drive the most sales in Beauty?
> Show me trending categories in Southeast Asia
```

The skill supports multi-turn conversations — ask follow-up questions and it remembers context.

## Requirements

- A [KaloData](https://kalodata.com) API token

## License

MIT
