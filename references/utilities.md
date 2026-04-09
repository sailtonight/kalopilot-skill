# Utilities & Other Tools

## User Collections

View the user's saved/followed items from KaloData:

| Tool | What it does |
|------|-------------|
| **Product Follow List** | User's saved products, supports sorting and pagination |
| **Shop Follow List** | User's saved shops |
| **Creator Follow List** | User's saved creators |
| **Video Follow List** | User's saved videos |
| **Video Script Follow List** | User's saved video scripts |

## URL Lookup

Paste any of these link types and KaloPilot will automatically parse and fetch the entity details:
- **KaloData links**: kalodata.com/product/xxx, kalodata.com/shop/xxx, etc.
- **TikTok links**: tiktok.com/@user/video/xxx, tiktok.com/live/xxx
- **Shopee / Lazada links**: cross-platform product lookup

## Filter Configuration

Retrieve the user's saved filter presets from KaloData. Supports types: product, shop, creator, video, livestream, category. Useful for applying the user's custom filter combos to ranking queries.

## FAQ Search

Search KaloData's knowledge base (powered by PGVector) for platform usage questions. Automatically selects the right knowledge base by region.

## Web Search

General web search via Tavily for supplementary context outside KaloData's dataset.

## Membership & Pricing

Query KaloData plan details and pricing. Automatically selects currency based on the user's business country.

## Credits

Most queries are included in the user's KaloData plan. Two tools have extra per-item costs:

| Tool | Cost | Cache |
|------|------|-------|
| Video Script Extraction | 1 credits/video | Redis 7 days + S3 |
| Product Comment Analysis | 1 credits/product | None |
