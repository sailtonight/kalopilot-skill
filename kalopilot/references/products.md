# Products

## Tools

| Tool | What it does |
|------|-------------|
| **Product Rankings** | Top products by revenue, sales, growth, price, commission. Supports filtering by category, shop, creator, video, livestream, price range, affiliate status, delivery type, launch date |
| **Product Detail** | Full metrics for specific products: revenue trends, sales volume, pricing, creator count, video count |
| **Selling Point Analysis** | AI-extracted selling points and product attributes with competitor comparison |
| **Comment Analysis** | Sentiment analysis of user reviews — pain points, satisfaction drivers, key themes. **100 credits/product** |
| **Image Search** | Upload a product photo to find similar products across all regions |

## Ranking Sort Options

revenue, video_revenue, product_card_revenue, commission_rate, revenue_growth_rate, sales_volumn, unit_price

## Ranking Filters

| Filter | Values | Example |
|--------|--------|---------|
| category_ids | Category ID list | Filter to Beauty subcategory |
| unit_price_range | Price range string | "$10-$50" |
| revenue_range | Revenue range string | Revenue tier filtering |
| is_affiliate | 0 or 1 | Affiliate products only |
| commission_rate | float or range | High-commission products |
| is_tts_product | 0 or 1 | Fully-managed (TTS) products |
| delivery_type | "local" / "global" | Local warehouse vs cross-border |
| launch_date | "<3" / "<7" / ">30" | New launches or established products |
| keyword | Product name search | Search by keyword |
| shop_id / creator_id / video_id / livestream_id | Entity ID | Products linked to a specific entity |

## Date Ranges

- Rankings: lastDay, last7Day, last30Day
- Detail: lastDay, last7Day, last30Day, last90Day, last180Day, last365Day

## Example Queries

- "美国 Beauty 类目近7天销量最高的商品"
- "帮我分析这个商品的卖点和用户评价"
- "找佣金率超过20%的联盟商品"
- "近3天新上架的爆款商品有哪些"
- "用这张图搜一下有没有类似的商品在卖"
