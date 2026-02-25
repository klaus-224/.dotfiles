---
name: slack
description: Reads Slack public channel data including channel lists, message history, and thread replies. Use when the user needs to find Slack channels, read messages, retrieve conversation history, or follow threaded discussions.
allowed-tools: Bash(slack:*)
---

# Slack Channel Reader

Read-only access to public Slack channels via the Slack Web API using `curl`. Requires a `SLACK_USER_TOKEN` environment variable with `channels:read` and `channels:history` scopes.

## Quick start

```bash
# list public channels
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.list?limit=100" | jq '.channels[] | {id, name}'

# get channel info
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.info?channel=C012AB3CD" | jq '.channel'

# read recent messages from a channel
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=C012AB3CD&limit=20" | jq '.messages'

# read thread replies
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.replies?channel=C012AB3CD&ts=1482960137.003543" | jq '.messages'
```

## Authentication

All requests use the `SLACK_USER_TOKEN` environment variable (a User OAuth token with `channels:read` and `channels:history` scopes). Pass it via the `Authorization` header:

```
Authorization: Bearer $SLACK_USER_TOKEN
```

## API Methods

### conversations.list

List public channels in the workspace. Requires `channels:read` scope.

```bash
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.list?limit=100" | jq .
```

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `limit` | number | No | Max results per page (default: 100, max: 1000) |
| `cursor` | string | No | Pagination cursor from previous `response_metadata.next_cursor` |
| `exclude_archived` | boolean | No | Exclude archived channels (default: false) |
| `types` | string | No | Channel types to include (default: `public_channel`) |

**Response fields:**

| Field | Description |
|---|---|
| `channels[].id` | Channel ID (e.g., `C012AB3CD`) — use this for other API calls |
| `channels[].name` | Channel name |
| `channels[].topic.value` | Channel topic |
| `channels[].purpose.value` | Channel purpose |
| `channels[].num_members` | Number of members |
| `channels[].is_archived` | Whether the channel is archived |
| `response_metadata.next_cursor` | Cursor for next page (empty string if no more results) |

**Examples:**

```bash
# find a channel by name
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.list?limit=200" | jq '.channels[] | select(.name == "general") | .id'

# list all non-archived channels (names and IDs)
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.list?exclude_archived=true&limit=200" | jq '.channels[] | {id, name}'
```

---

### conversations.info

Get detailed information about a specific channel. Requires `channels:read` scope.

```bash
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.info?channel=CHANNEL_ID" | jq .
```

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `channel` | string | Yes | Channel ID |
| `include_num_members` | boolean | No | Include member count |

**Response fields:**

| Field | Description |
|---|---|
| `channel.id` | Channel ID |
| `channel.name` | Channel name |
| `channel.topic.value` | Current topic |
| `channel.purpose.value` | Current purpose |
| `channel.creator` | User ID of channel creator |
| `channel.created` | Unix timestamp of creation |
| `channel.is_archived` | Whether the channel is archived |
| `channel.num_members` | Member count (if requested) |

---

### conversations.history

Fetch message history from a channel. Requires `channels:history` scope. Returns messages in reverse chronological order (newest first).

```bash
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=CHANNEL_ID&limit=20" | jq .
```

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `channel` | string | Yes | Channel ID |
| `limit` | number | No | Max messages to return (default: 100, max: 999) |
| `cursor` | string | No | Pagination cursor from `response_metadata.next_cursor` |
| `oldest` | string | No | Only messages after this Unix timestamp |
| `latest` | string | No | Only messages before this Unix timestamp (default: now) |
| `inclusive` | boolean | No | Include messages with `oldest`/`latest` timestamps (default: false) |
| `include_all_metadata` | boolean | No | Return all metadata on messages |

**Response fields:**

| Field | Description |
|---|---|
| `messages[].type` | Always `"message"` for user messages |
| `messages[].user` | User ID of the author |
| `messages[].text` | Message text content |
| `messages[].ts` | Message timestamp (unique ID within the channel) |
| `messages[].thread_ts` | Present if the message is part of a thread |
| `messages[].reply_count` | Number of replies (on parent messages) |
| `messages[].reactions` | Array of reactions, if any |
| `has_more` | `true` if more messages exist beyond this page |
| `response_metadata.next_cursor` | Cursor for next page |

**Examples:**

```bash
# read last 10 messages
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=C012AB3CD&limit=10" | jq '.messages[] | {user, text, ts}'

# retrieve a single message by its ts
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=C012AB3CD&oldest=1512085950.000216&inclusive=true&limit=1" | jq '.messages[0]'

# messages from the last 24 hours
OLDEST=$(date -v-1d +%s 2>/dev/null || date -d '1 day ago' +%s)
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=C012AB3CD&oldest=$OLDEST&limit=100" | jq '.messages'

# messages in a time range
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=C012AB3CD&oldest=1700000000&latest=1700100000&inclusive=true&limit=100" | jq '.messages'
```

---

### conversations.replies

Retrieve all replies in a message thread. Requires `channels:history` scope. The first message in the response is the parent message, followed by threaded replies in chronological order (oldest first).

```bash
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.replies?channel=CHANNEL_ID&ts=THREAD_TS" | jq .
```

**Parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `channel` | string | Yes | Channel ID |
| `ts` | string | Yes | Timestamp of the parent message (the `thread_ts` value) |
| `limit` | number | No | Max messages to return (default: 1000) |
| `cursor` | string | No | Pagination cursor from `response_metadata.next_cursor` |
| `oldest` | string | No | Only replies after this Unix timestamp |
| `latest` | string | No | Only replies before this Unix timestamp |
| `inclusive` | boolean | No | Include messages at `oldest`/`latest` boundary |

**Response fields:**

| Field | Description |
|---|---|
| `messages[0]` | The parent message |
| `messages[1..]` | Thread replies in chronological order |
| `messages[].thread_ts` | Thread parent timestamp (same for all messages in the thread) |
| `messages[].parent_user_id` | User ID of the parent message author (on replies) |
| `messages[].ts` | Message timestamp / unique ID |
| `has_more` | `true` if more replies exist beyond this page |

**Examples:**

```bash
# get full thread
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.replies?channel=C012AB3CD&ts=1482960137.003543" | jq '.messages[] | {user, text, ts}'

# get only the latest 5 replies
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.replies?channel=C012AB3CD&ts=1482960137.003543&limit=5" | jq '.messages'
```

## Pagination

All list methods use cursor-based pagination. When `response_metadata.next_cursor` is non-empty, pass it as the `cursor` parameter to get the next page.

```bash
# first page
RESPONSE=$(curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=C012AB3CD&limit=100")
echo "$RESPONSE" | jq '.messages'

# next page (if has_more is true)
CURSOR=$(echo "$RESPONSE" | jq -r '.response_metadata.next_cursor')
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=C012AB3CD&limit=100&cursor=$CURSOR" | jq '.messages'
```

## Detecting Threads

A message is part of a thread if it has a `thread_ts` field:
- **Parent message**: `ts == thread_ts`
- **Reply**: `ts != thread_ts`

```bash
# find threaded messages in history
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=C012AB3CD&limit=50" \
  | jq '.messages[] | select(.thread_ts != null and .reply_count > 0) | {ts, text, reply_count}'
```

## Example: Find a channel and read its recent messages

```bash
# 1. find the channel ID for #engineering
CHANNEL_ID=$(curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.list?limit=200" \
  | jq -r '.channels[] | select(.name == "engineering") | .id')

# 2. read the last 20 messages
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=$CHANNEL_ID&limit=20" \
  | jq '.messages[] | {user, text, ts, reply_count}'
```

## Example: Read a full thread

```bash
# 1. get channel history and find a threaded message
RESPONSE=$(curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=C012AB3CD&limit=50")

# 2. extract the thread_ts of the first threaded parent
THREAD_TS=$(echo "$RESPONSE" | jq -r '[.messages[] | select(.reply_count > 0)][0].ts')

# 3. fetch the full thread
curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.replies?channel=C012AB3CD&ts=$THREAD_TS" \
  | jq '.messages[] | {user, text, ts}'
```

## Example: Search messages in a time window

```bash
# messages from the last 7 days in #general
CHANNEL_ID="C012AB3CD"
OLDEST=$(date -v-7d +%s 2>/dev/null || date -d '7 days ago' +%s)

curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=$CHANNEL_ID&oldest=$OLDEST&limit=200" \
  | jq '.messages[] | {user, text, ts}'
```

## Error handling

Always check `ok` in the response. Common errors:

| Error | Cause |
|---|---|
| `channel_not_found` | Invalid channel ID |
| `not_in_channel` | Bot/user lacks access (user tokens can access any public channel) |
| `invalid_auth` | Token is invalid or expired |
| `missing_scope` | Token lacks required scopes |
| `ratelimited` | Too many requests — check `Retry-After` header |

```bash
# check for errors
RESPONSE=$(curl -s -H "Authorization: Bearer $SLACK_USER_TOKEN" \
  "https://slack.com/api/conversations.history?channel=C012AB3CD&limit=10")
OK=$(echo "$RESPONSE" | jq -r '.ok')
if [ "$OK" != "true" ]; then
  echo "Error: $(echo "$RESPONSE" | jq -r '.error')"
fi
```

## Rate limits

Slack API methods have rate limits. If you receive a `ratelimited` error, wait for the duration specified in the `Retry-After` response header before retrying. For `conversations.history` and `conversations.replies`, the rate limit is Tier 3 (approximately 50 requests per minute for Marketplace/internal apps).
