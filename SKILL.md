---
name: kalopilot
description: Query TikTok e-commerce data (products, shops, creators, videos, livestreams, categories) via the KaloPilot AI agent. Use this skill whenever the user asks about TikTok Shop data, product rankings, creator performance, shop analytics, category trends, livestream metrics, or any TikTok e-commerce insight — even if they don't say "KaloPilot" explicitly. Also trigger when the user says "ask pilot", "check kalodata", or mentions TikTok sales/revenue data.
---

# KaloPilot — TikTok E-commerce Data Assistant

This skill lets you query TikTok Shop data through the KaloPilot AI agent. KaloPilot has access to 20+ specialized tools covering products, shops, creators, videos, livestreams, and categories across all TikTok Shop regions.

## Authentication

The token is stored as plain text in `~/.kalopilot/token`. The first request will fail with a clear error if it's missing — that's expected on first use.

**When the token is missing, don't just say "I need a token." Walk the user through getting one:**

1. Go to [kalodata.com/pilot](https://kalodata.com/pilot) and log in.
2. In the bottom-left of the sidebar, click **Connect OpenClaw** ("Skill installation tutorial").
3. In the **OpenClaw Integration Guide** dialog that opens, copy the string under **Current Account Token** — a long hex string, e.g. `89e7f60c...5be6b9`.
4. Paste it back here, and you'll save it for them.

Once the user provides the token, save it (this also creates the directory and locks down permissions):

```bash
mkdir -p ~/.kalopilot && echo -n "<token>" > ~/.kalopilot/token && chmod 600 ~/.kalopilot/token
```

Then confirm it's saved and immediately retry their original question — don't make them ask again.

To check whether a token is already configured before prompting:

```bash
[ -s ~/.kalopilot/token ] && echo "configured" || echo "missing"
```

If the user ever reports auth errors (401 / invalid token), the saved token may be stale — guide them through the same steps to grab a fresh **Current Account Token** and overwrite the file with the command above.

## API Endpoint

The skill uses an **async submit + poll** flow. Submitting returns a `task_id`
immediately; the agent then runs to completion on the server. You poll for the
result with short requests, so no connection is held open — gateway idle
timeouts never apply, no matter how long the analysis takes.

```
POST https://staging.kalodata.com/api/pilot/skill/ext/v1/chat/async/submit
GET  https://staging.kalodata.com/api/pilot/skill/ext/v1/chat/async/result?task_id=<id>
Authorization: Bearer <token>
```

## Making a Request

Use `scripts/pilot.sh` to manage queries. The script handles token loading,
submitting the task, and polling — no background processes or stale files.

**Response time by complexity:**
- Simple queries (single-dimension lookup, e.g. "美国热门商品"): ~1 minute
- Complex queries (cross-dimension, diagnostics, comparisons): 2–3 minutes
- Very complex (multi-step analysis with reports): several minutes (no upper-bound timeout)

**Step 1 — Submit the query:**

```bash
bash <skill-path>/scripts/pilot.sh query "<user question>"
```

With task_id for follow-up questions:

```bash
bash <skill-path>/scripts/pilot.sh query "<user question>" "<task_id>"
```

This returns a `task_id` immediately (saved for the next step). If credits are
insufficient or the token is invalid, you get the error here right away. Tell
the user the analysis is running.

**Step 2 — Poll for the result:**

Poll based on query complexity:
- Simple query → first poll after **45 seconds**
- Complex query → first poll after **90 seconds**
- While `status` is `running`, poll again every **30 seconds** until it changes

```bash
bash <skill-path>/scripts/pilot.sh result
```

Each call returns the current state as JSON. Read `data.status`:
- `running` → still working; wait and poll again.
- `completed` → the result fields (`text`, `report`, …) are populated; render them.
- `error` → show `data.error.message`.
- `cancelled` → the task was cancelled.

`result` polls the same `task_id` from step 1; pass an explicit `task_id` as an
argument to poll a specific task.

### Multi-turn Conversations

The first request returns a `task_id` in the response. Always reuse that `task_id` for follow-up questions on the same topic — this gives KaloPilot conversation context so it can understand references like "the first one" or "compare it with yesterday".

**Example flow:**

1. First message: `{"query": "美国热门商品有哪些？"}` → response includes `"task_id": "abc123"`
2. Follow-up: `{"query": "第一名的销售趋势怎么样？", "task_id": "abc123"}`
3. Another follow-up: `{"query": "对比一下英国市场", "task_id": "abc123"}`

When the user switches to a clearly different topic, start fresh without `task_id`.

## Response Format

All async responses are wrapped in `{ "success", "data", "message", "code" }`.
The fields you care about live under `data`.

**Submit** (`query`):

```json
{ "success": true, "data": { "task_id": "abc123", "status": "submitted" } }
```

**Poll while running** (`result`):

```json
{ "success": true, "data": { "task_id": "abc123", "status": "running" } }
```

**Poll once completed** (`result`):

```json
{
  "success": true,
  "data": {
    "task_id": "abc123",
    "status": "completed",
    "message_id": "456",
    "text": "The main analysis text...",
    "report": "# Detailed Report\n\n...",
    "report_url": "https://staging.kalodata.com/...",
    "token_usage": {...},
    "credits_consumed": 10
  }
}
```

### How to display the response

Only render once `data.status` is `completed`. Then, reading from `data`:

1. Show the `text` field — this is the primary analysis.
2. If `report` is not null, display it as well (it's a markdown report with tables and structured data).
3. If `report_url` is not null, show it as a clickable link so the user can open the full report in their browser, e.g. "查看完整报告：[链接]". **CRITICAL: Copy the `report_url` value verbatim from the API response. NEVER construct, guess, or fabricate this URL — the `task_id` and `tool_call_id` parameters in the URL are unique server-generated values that cannot be inferred. If `report_url` is absent or null in the response, do not show any link.**
4. Mention credits consumed at the end, e.g. "(consumed 10 credits)".

### Error responses

Two shapes:
- **Request rejected** (e.g. insufficient credits, invalid token — surfaced by `query`): `success` is `false` with a top-level `message` and `code`.
- **Task failed** (surfaced by `result`): `data.status` is `error` with `data.error.message`.

Common cases:
- **Insufficient credits**: tell the user they need to top up on KaloData.
- **Membership required**: relay the message — some data needs a higher plan.
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
