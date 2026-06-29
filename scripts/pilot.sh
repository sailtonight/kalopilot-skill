#!/usr/bin/env bash
set -euo pipefail

# KaloPilot skill client — native async (submit + poll).
#
# `query` submits a task and returns immediately with a task_id; the agent runs
# to completion on the server. `result` polls for the outcome with a short
# request. No long-lived connection is held, so gateway idle timeouts never
# apply regardless of how long the analysis takes.

PILOT_DIR="$HOME/.kalopilot"
TOKEN_FILE="$PILOT_DIR/token"
TASK_FILE="$PILOT_DIR/task_id"

BASE_URL="https://staging.kalodata.com/api/pilot/skill/ext/v1"
REQ_TIMEOUT=30  # seconds; submit/result are both short requests

usage() {
  echo "Usage: pilot.sh <command> [args]"
  echo ""
  echo "Commands:"
  echo "  query <question> [task_id]   Submit a query, returns task_id immediately"
  echo "  result [task_id]             Poll for the result (running / completed / error)"
  echo ""
  echo "Example:"
  echo "  pilot.sh query '美国热门商品有哪些？'"
  echo "  pilot.sh result        # repeat until status != running"
  exit 1
}

require_token() {
  if [ ! -s "$TOKEN_FILE" ]; then
    echo "ERROR: Token not found. Save your KaloData token first:"
    echo "  mkdir -p $PILOT_DIR && echo -n 'YOUR_TOKEN' > $TOKEN_FILE && chmod 600 $TOKEN_FILE"
    exit 1
  fi
}

# Extract a string field from a (possibly wrapped) JSON blob. Portable: no jq.
json_str() {
  # $1 = field name, reads JSON from stdin
  grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" | head -1 \
    | sed -E "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"([^\"]*)\".*/\1/"
}

cmd_query() {
  local question="${1:?Missing query argument}"
  local task_id="${2:-}"
  require_token

  local token
  token=$(cat "$TOKEN_FILE")

  # Escape backslashes and double quotes so the question is valid JSON.
  local q=${question//\\/\\\\}
  q=${q//\"/\\\"}

  local payload
  if [ -n "$task_id" ]; then
    payload="{\"query\": \"$q\", \"task_id\": \"$task_id\"}"
  else
    payload="{\"query\": \"$q\"}"
  fi

  local body
  if ! body=$(curl -s -X POST "$BASE_URL/chat/async/submit" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    -d "$payload" \
    --max-time "$REQ_TIMEOUT"); then
    echo "ERROR: submit request failed (network/timeout)."
    exit 1
  fi

  local new_task_id
  new_task_id=$(printf '%s' "$body" | json_str task_id)

  if [ -z "$new_task_id" ]; then
    echo "ERROR: submit did not return a task_id. Server response:"
    echo "$body"
    exit 1
  fi

  printf '%s' "$new_task_id" > "$TASK_FILE"
  echo "$body"
  echo ""
  echo "Submitted. task_id=$new_task_id — poll with 'pilot.sh result' until status != running."
}

cmd_result() {
  local task_id="${1:-}"
  if [ -z "$task_id" ]; then
    if [ ! -s "$TASK_FILE" ]; then
      echo "ERROR: No task_id. Run 'pilot.sh query ...' first, or pass a task_id."
      exit 1
    fi
    task_id=$(cat "$TASK_FILE")
  fi
  require_token

  local token
  token=$(cat "$TOKEN_FILE")

  local body
  if ! body=$(curl -s -G "$BASE_URL/chat/async/result" \
    --data-urlencode "task_id=$task_id" \
    -H "Authorization: Bearer $token" \
    --max-time "$REQ_TIMEOUT"); then
    echo "ERROR: result request failed (network/timeout). Try again."
    exit 1
  fi

  echo "$body"
}

# Main
[ $# -lt 1 ] && usage

case "$1" in
  query)         shift; cmd_query "$@" ;;
  result|status) shift || true; cmd_result "$@" ;;
  *)             usage ;;
esac
