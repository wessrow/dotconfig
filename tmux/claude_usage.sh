#!/usr/bin/env bash
# Shows the account-wide Claude usage limit that gates whether you can keep
# running Claude Code: the 5-hour rolling window ("session") utilisation.
#
# Source is the cache written by claude_usage_poll.sh, which runs on a timer
# (launchd on macOS, cron on Linux) because Claude Code itself only refreshes
# its usage figures on interactive startup / `/usage`, never mid-session. See
# claude_usage_poll.sh for the why and the wiring.
#
# Falls back to Claude Code's own cache in ~/.claude.json
# (key cachedUsageUtilization) if the poller cache is missing.

# nf-md-robot (U+F06A9). Encoded as raw UTF-8 bytes so the literal glyph
# doesn't have to survive editing. Swap to fa-robot with '\xef\x95\x84'.
ICON=$(printf '\xf3\xb0\x9a\xa9')

CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-usage/usage.json"
CLAUDE_JSON="$HOME/.claude.json"

# Consider the poller cache stale after this long; append "?" when it is.
STALE_SECONDS=1800

PCT=$(python3 - "$CACHE_FILE" "$CLAUDE_JSON" "$STALE_SECONDS" <<'PYEOF'
import json, os, sys, time

cache_file, claude_json, stale = sys.argv[1], sys.argv[2], int(sys.argv[3])

# Preferred source: the poller cache.
try:
    with open(cache_file) as f:
        d = json.load(f)
    u = d.get("session_pct")
    if u is not None:
        mark = "?" if time.time() - d.get("updated", 0) > stale else ""
        print(f"{int(round(u))}%{mark}")
        sys.exit(0)
except Exception:
    pass

# Fallback: Claude Code's own cache (refreshed only on interactive startup).
try:
    with open(claude_json) as f:
        d = json.load(f)
    u = d["cachedUsageUtilization"]["utilization"]["five_hour"]["utilization"]
    print(f"{int(round(u))}%" if u is not None else "--%")
except Exception:
    print("--%")
PYEOF
)

echo "$ICON ${PCT:---%}"
