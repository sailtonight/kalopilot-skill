#!/usr/bin/env bash
set -euo pipefail

PILOT_DIR="$HOME/.kalopilot"
TOKEN_FILE="$PILOT_DIR/token"
RESULT_FILE="$PILOT_DIR/result.json"
ERR_FILE="$PILOT_DIR/err.log"
PID_FILE="$PILOT_DIR/pid"

usage() {
  echo "Usage: pilot.sh <command> [args]"
  echo ""
  echo "Commands:"
  echo "  query <question> [task_id]   Send a query (runs in background)"
  echo "  status                       Check if query is still running"
  echo "  result                       Read result and clean up"
  echo ""
  echo "Example:"
  echo "  pilot.sh query '美国热门商品有哪些？'"
  echo "  pilot.sh status"
  echo "  pilot.sh result"
  exit 1
}

cmd_query() {
  local question="${1:?Missing query argument}"
  local task_id="${2:-}"

  # Check token
  if [ ! -f "$TOKEN_FILE" ]; then
    echo "ERROR: Token not found. Save your KaloData token first:"
    echo "  mkdir -p $PILOT_DIR && echo -n 'YOUR_TOKEN' > $TOKEN_FILE && chmod 600 $TOKEN_FILE"
    exit 1
  fi

  # Abort if a previous query is still running
  if [ -f "$PID_FILE" ]; then
    local old_pid
    old_pid=$(cat "$PID_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
      echo "ERROR: A query is still running (PID $old_pid). Wait for it to finish, or kill it:"
      echo "  kill $old_pid"
      exit 1
    fi
  fi

  # Clean up previous results
  rm -f "$RESULT_FILE" "$ERR_FILE" "$PID_FILE"

  local token
  token=$(cat "$TOKEN_FILE")

  # Build JSON payload
  local payload
  if [ -n "$task_id" ]; then
    payload="{\"query\": \"$question\", \"task_id\": \"$task_id\"}"
  else
    payload="{\"query\": \"$question\"}"
  fi

  # Launch in background
  curl -s -X POST "https://staging.kalodata.com/api/pilot/skill/ext/v1/chat/sync" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $token" \
    -d "$payload" \
    --max-time 600 \
    -o "$RESULT_FILE" 2>"$ERR_FILE" &
  local pid=$!
  echo "$pid" > "$PID_FILE"

  echo "Query launched (PID $pid). Checking for early errors..."

  # Early error check after 2 seconds
  sleep 2
  if ! kill -0 "$pid" 2>/dev/null; then
    echo ""
    if [ -s "$RESULT_FILE" ]; then
      echo "ERROR: Request failed immediately:"
      cat "$RESULT_FILE"
    elif [ -s "$ERR_FILE" ]; then
      echo "ERROR:"
      cat "$ERR_FILE"
    else
      echo "ERROR: Process exited with no output."
    fi
    rm -f "$PID_FILE"
    exit 1
  fi

  echo "Running. Use 'pilot.sh status' to check, 'pilot.sh result' to read when done."
}

cmd_status() {
  if [ ! -f "$PID_FILE" ]; then
    echo "No active query."
    # Check if there's an unread result
    if [ -f "$RESULT_FILE" ]; then
      echo "Unread result available. Run 'pilot.sh result' to read it."
    fi
    return
  fi

  local pid
  pid=$(cat "$PID_FILE")
  if kill -0 "$pid" 2>/dev/null; then
    echo "running (PID $pid)"
  else
    echo "done"
    rm -f "$PID_FILE"
  fi
}

cmd_result() {
  # Prevent reading while still running
  if [ -f "$PID_FILE" ]; then
    local pid
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      echo "ERROR: Query still running (PID $pid). Wait for it to finish."
      exit 1
    fi
    rm -f "$PID_FILE"
  fi

  if [ ! -f "$RESULT_FILE" ]; then
    echo "ERROR: No result found. Did you run a query first?"
    exit 1
  fi

  cat "$RESULT_FILE"

  # Clean up
  rm -f "$RESULT_FILE" "$ERR_FILE" "$PID_FILE"
}

# Main
[ $# -lt 1 ] && usage

case "$1" in
  query)  shift; cmd_query "$@" ;;
  status) cmd_status ;;
  result) cmd_result ;;
  *)      usage ;;
esac
