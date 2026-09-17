#!/usr/bin/env bash
# Shows the account-wide Claude usage limit that gates whether you can keep
# running Claude Code: the 5-hour rolling window ("session") utilisation, plus
# a countdown to when that session limit resets.
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

OUT=$(python3 - "$CACHE_FILE" "$CLAUDE_JSON" "$STALE_SECONDS" <<'PYEOF'
import json, sys, time
from datetime import datetime

cache_file, claude_json, stale = sys.argv[1], sys.argv[2], int(sys.argv[3])

def fmt_remaining(epoch):
    if epoch is None:
        return None
    remaining = epoch - time.time()
    if remaining <= 0:
        return "now"
    h, m = int(remaining // 3600), int((remaining % 3600) // 60)
    return f"{h}h{m:02d}m" if h else f"{m}m"

pct_str = None
reset_str = None

# Preferred source: the poller cache.
try:
    with open(cache_file) as f:
        d = json.load(f)
    u = d.get("session_pct")
    if u is not None:
        mark = "?" if time.time() - d.get("updated", 0) > stale else ""
        pct_str = f"{int(round(u))}%{mark}"
        reset_str = fmt_remaining(d.get("session_reset"))
except Exception:
    pass

# Fallback: Claude Code's own cache (refreshed only on interactive startup).
if pct_str is None:
    try:
        with open(claude_json) as f:
            d = json.load(f)
        five_hour = d["cachedUsageUtilization"]["utilization"]["five_hour"]
        u = five_hour.get("utilization")
        pct_str = f"{int(round(u))}%" if u is not None else "--%"
        resets_at = five_hour.get("resets_at")
        if resets_at:
            reset_str = fmt_remaining(datetime.fromisoformat(resets_at).timestamp())
    except Exception:
        pct_str = "--%"

print(f"{pct_str or '--%'}|{reset_str or '--'}")
PYEOF
)

IFS='|' read -r PCT RESET <<< "$OUT"

echo "$ICON ${PCT:---%} · Resets: ${RESET:---}"
