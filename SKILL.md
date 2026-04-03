---
name: kalopilot
description: Query TikTok e-commerce data (products, shops, creators, videos, livestreams, categories) via the KaloPilot AI agent. Use this skill whenever the user asks about TikTok Shop data, product rankings, creator performance, shop analytics, category trends, livestream metrics, or any TikTok e-commerce insight — even if they don't say "KaloPilot" explicitly. Also trigger when the user says "ask pilot", "check kalodata", or mentions TikTok sales/revenue data.
---

# KaloPilot — TikTok E-commerce Data Assistant

This skill lets you query TikTok Shop data through the KaloPilot AI agent. KaloPilot has access to 20+ specialized tools covering products, shops, creators, videos, livestreams, and categories across all TikTok Shop regions.

## Authentication

Token is stored in `~/.kalopilot/config.json`:

```json
{"token": "your-token-here"}
```

Read the token before each request. If the file doesn't exist, ask the user for their KaloData token, then save it:

```bash
mkdir -p ~/.kalopilot && echo '{"token": "<token>"}' > ~/.kalopilot/config.json && chmod 600 ~/.kalopilot/config.json
```

## API Endpoint

```
POST https://staging.kalodata.com/api/pilot/skill/ext/v1/chat/sync
Content-Type: application/json
Authorization: Bearer <token>
```

## Making a Request

The API typically responds in 2–3 minutes but can take up to 10 minutes for complex queries. Choose the appropriate execution strategy based on your environment:

### Strategy A: Background execution (preferred)

If your shell tool supports background execution with async notification (e.g. Bash tool's `run_in_background: true`), use this approach:

1. Launch the curl command in the background with `run_in_background: true` and `timeout: 600000`.
2. Tell the user the query is running and you'll share results when ready.
3. Wait for the automatic completion notification — do NOT poll or sleep.

### Strategy B: Foreground execution with polling

If your shell tool does NOT support background execution or async notification:

1. Launch the curl command as a background shell process, writing output to a temp file:
   ```bash
   curl -s -X POST "https://staging.kalodata.com/api/pilot/skill/ext/v1/chat/sync" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $TOKEN" \
     -d '{"query": "<user question>", "task_id": "<id or null>"}' \
     --max-time 600 \
     -o /tmp/kalopilot_result.json 2>/tmp/kalopilot_err.log &
   echo $!
   ```
2. Tell the user the query is running (typically 2–3 min).
3. Poll every 30 seconds by checking if the process is still alive:
   ```bash
   kill -0 <PID> 2>/dev/null && echo "running" || echo "done"
   ```
4. Once done, read the result:
   ```bash
   cat /tmp/kalopilot_result.json
   ```

### Curl command

Regardless of strategy, the curl command is the same:

```bash
curl -s -X POST "https://staging.kalodata.com/api/pilot/skill/ext/v1/chat/sync" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"query": "<user question>", "task_id": "<id or null>"}' \
  --max-time 600
```

Always set `--max-time 600` on curl. If your shell tool has a timeout parameter, set it to at least 600000 ms (10 minutes).

### Multi-turn Conversations

The first request returns a `task_id` in the response. Always reuse that `task_id` for follow-up questions on the same topic — this gives KaloPilot conversation context so it can understand references like "the first one" or "compare it with yesterday".

**Example flow:**

1. First message: `{"query": "美国热门商品有哪些？"}` → response includes `"task_id": "abc123"`
2. Follow-up: `{"query": "第一名的销售趋势怎么样？", "task_id": "abc123"}`
3. Another follow-up: `{"query": "对比一下英国市场", "task_id": "abc123"}`

When the user switches to a clearly different topic, start fresh without `task_id`.

## Response Format

```json
{
  "task_id": "abc123",
  "message_id": "456",
  "text": "The main analysis text...",
  "report": "# Detailed Report\n\n...",
  "token_usage": {...},
  "credits_consumed": 10
}
```

### How to display the response

1. Show the `text` field — this is the primary analysis.
2. If `report` is not null, display it as well (it's a markdown report with tables and structured data).
3. Mention credits consumed at the end, e.g. "(consumed 10 credits)".

### Error responses

The API returns errors as JSON with a `message` field. Common cases:
- **Insufficient credits**: tell the user they need to top up on KaloData.
- **Timeout**: suggest the user try a more specific query.
- Other errors: show the error message directly.

## What Users Can Ask

KaloPilot covers these dimensions across all TikTok Shop regions (US, UK, ID, MY, TH, VN, PH, SG, MX, DE, IT, FR, ES, BR, JP):

- **Products**: rankings, sales trends, price analysis, breakout products, selling point analysis, comment/review analysis, image search (find similar products by photo)
- **Shops**: store rankings, revenue, product mix, growth metrics
- **Creators/Influencers**: performance, GMV, follower analysis, collaboration data, creator search
- **Videos**: viral product videos, engagement metrics, conversion analysis, video script extraction
- **Livestreams**: live sales data, viewer metrics, product performance during streams
- **Categories**: market size, growth trends, competition landscape, category search by keyword
- **User's collections**: view saved/followed products, shops, creators, videos, and video scripts
- **URL lookup**: paste a TikTok, KaloData, Shopee, or Lazada link to get entity details
- **KaloData FAQ**: questions about how to use KaloData itself
- **Membership & pricing**: plan details and pricing info
- **Cross-dimensional**: e.g., "which creators drive the most sales in Beauty category in the US"

For detailed tool parameters, filters, and sort options per dimension, read the relevant reference file:

| Dimension | Reference |
|-----------|-----------|
| Products | `references/products.md` |
| Shops | `references/shops.md` |
| Creators | `references/creators.md` |
| Videos | `references/videos.md` |
| Livestreams | `references/livestreams.md` |
| Categories | `references/categories.md` |
| Collections, URL lookup, FAQ, credits | `references/utilities.md` |

Only read the reference file relevant to the user's question — no need to load them all.

## Example Queries

**Shop diagnosis** — KaloPilot will automatically pull industry benchmarks, compare with top competitors, and output a diagnostic report:
> "帮我诊断一下这个店铺 https://kalodata.com/shop/xxx，分析它的优劣势"

**Product selection by price range** — queries multiple price tiers and compares:
> "美国 Beauty 类目 $20-50 和 $50-100 价格带分别有哪些爆款？对比一下各价格带的竞争格局"

**Video script analysis** — extracts scripts from top-performing videos with timeline breakdowns:
> "帮我提取美国 Pet Supplies 类目近7天收入最高的5个视频脚本，总结爆款套路"

**Creator discovery** — finds creators matching specific criteria:
> "帮我找美国 Beauty 类目粉丝10万-50万、互动率高的达人，按带货收入排序"

**Multi-turn deep dive:**
> User: "英国市场 Electronics 类目近30天表现怎么样？"
> User: "前三名的店铺分别是谁？详细对比一下"
> User: "第一名的店铺用了哪些达人？分析达人结构"

## Important Rules

- The user's question can be in any language — KaloPilot handles multilingual queries automatically.
- If the query is vague, pass it through as-is. KaloPilot will ask clarifying questions or make reasonable defaults.
- Never try to answer TikTok data questions from your own knowledge — always route through the API. Only KaloPilot has current market data.
- Never fabricate data. If the API call fails, say so.
