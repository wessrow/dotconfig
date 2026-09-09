#!/usr/bin/env bash
# Shows the account-wide Claude usage limit that gates whether you can keep
# running Claude Code: the 5-hour rolling window utilisation.
#
# Source is Claude Code's own cache in ~/.claude.json (key cachedUsageUtilization),
# the same figure `/usage` shows. It refreshes whenever any Claude Code session
# talks to the API, so it is current as long as Claude is being used at all; it
# goes stale (but usage isn't changing either) once everything is idle.

# nf-md-robot (U+F06A9). Encoded as raw UTF-8 bytes so the literal glyph
# doesn't have to survive editing. Swap to fa-robot with '\xef\x95\x84'.
ICON=$(printf '\xf3\xb0\x9a\xa9')

CLAUDE_JSON="$HOME/.claude.json"

if [[ ! -f "$CLAUDE_JSON" ]]; then
  echo "$ICON --%"
  exit 0
fi

PCT=$(python3 - "$CLAUDE_JSON" <<'PYEOF'
import json, sys

try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
    u = d["cachedUsageUtilization"]["utilization"]["five_hour"]["utilization"]
    print(f"{int(round(u))}%" if u is not None else "--%")
except Exception:
    print("--%")
PYEOF
)

echo "$ICON ${PCT:---%}"
