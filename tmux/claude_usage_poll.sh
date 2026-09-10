#!/usr/bin/env bash
# Background poller for the Claude usage tmux widget.
#
# Claude Code only writes its usage figures to ~/.claude.json on *interactive*
# session startup and when you run `/usage` by hand - not on every API turn and
# not from headless `claude -p`. So a long-lived session leaves the widget
# frozen. This script asks for the numbers explicitly and caches them where
# claude_usage.sh can read them.
#
#   claude -p '/usage'  costs $0 / 0 tokens (it is a slash command, no
#   inference) but takes a few seconds, so it must run out-of-band on a timer -
#   see launchd/local.claude-usage.plist.template (macOS) or a cron entry
#   (Linux). Do NOT call it inline from the tmux status line.
#
# Cache file: ${XDG_CACHE_HOME:-~/.cache}/claude-usage/usage.json
#   {"session_pct": <int>, "week_pct": <int>, "updated": <epoch seconds>}
# On failure the previous cache is left untouched (last good value wins).

set -euo pipefail

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage"
CACHE_FILE="$CACHE_DIR/usage.json"
mkdir -p "$CACHE_DIR"

# Resolve the claude binary. launchd gives us a minimal PATH, so look in the
# usual spots before giving up.
CLAUDE=""
for cand in "$HOME/.local/bin/claude" "$(command -v claude 2>/dev/null || true)" \
            /opt/homebrew/bin/claude /usr/local/bin/claude; do
  if [[ -n "$cand" && -x "$cand" ]]; then
    CLAUDE="$cand"
    break
  fi
done
if [[ -z "$CLAUDE" ]]; then
  echo "$(date '+%F %T') claude binary not found" >&2
  exit 1
fi

# Optional hard timeout if coreutils' timeout / gtimeout is around.
TIMEOUT=()
if command -v timeout >/dev/null 2>&1; then
  TIMEOUT=(timeout 30)
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT=(gtimeout 30)
fi

RESP_FILE="$CACHE_DIR/last_response.json"
# ${TIMEOUT[@]+...} guard keeps this working under `set -u` on bash 3.2 (macOS
# /bin/bash) when the array is empty.
${TIMEOUT[@]+"${TIMEOUT[@]}"} "$CLAUDE" -p '/usage' --output-format json >"$RESP_FILE" 2>/dev/null || true
if [[ ! -s "$RESP_FILE" ]]; then
  echo "$(date '+%F %T') empty response from claude -p /usage" >&2
  exit 1
fi

python3 - "$CACHE_FILE" "$RESP_FILE" <<'PYEOF'
import json, os, re, sys, time

cache_file, resp_file = sys.argv[1], sys.argv[2]
with open(resp_file) as f:
    raw = f.read()

try:
    text = json.loads(raw).get("result", "")
except Exception:
    text = raw

def pct(pattern):
    m = re.search(pattern, text, re.IGNORECASE)
    return int(m.group(1)) if m else None

session = pct(r"Current session:\s*(\d+)%")
week = pct(r"Current week \(all models\):\s*(\d+)%")

if session is None and week is None:
    sys.stderr.write(time.strftime("%F %T") + " could not parse usage from:\n" + text[:400] + "\n")
    sys.exit(1)

payload = {"session_pct": session, "week_pct": week, "updated": int(time.time())}
tmp = cache_file + ".tmp"
with open(tmp, "w") as f:
    json.dump(payload, f)
os.replace(tmp, cache_file)
print(payload)
PYEOF
