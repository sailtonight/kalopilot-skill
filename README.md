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

Copy the `kalopilot/` folder into your Claude skills directory:

```bash
# Claude Code
cp -r kalopilot/ .claude/skills/kalopilot/

# Or globally
cp -r kalopilot/ ~/.claude/skills/kalopilot/
```

## Setup

You need a KaloData account with API access. On first use, the skill will ask for your token and save it to `~/.kalopilot/config.json`.

Or set it up manually:

```bash
mkdir -p ~/.kalopilot
echo '{"token": "your-token-here"}' > ~/.kalopilot/config.json
chmod 600 ~/.kalopilot/config.json
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

- A [KaloData](https://kalodata.com) account with credits
- Claude Code, Claude Desktop, or Claude.ai

## License

MIT
