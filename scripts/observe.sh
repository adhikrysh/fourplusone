#!/usr/bin/env bash
# Stop hook entry point. Saves the turn that just ended, then hands it to the
# background worker and returns immediately so the agent is never slowed down.
set -euo pipefail

# The observer's own `claude -p` session also fires this hook. Ignore it.
[ -n "${FOURPLUSONE_OBSERVER:-}" ] && exit 0

# jq parses the hook input and the transcript. Without it, tell the developer
# how to install it instead of failing with "jq: command not found".
if ! command -v jq >/dev/null 2>&1; then
  printf '%s\n' '{"systemMessage": "fourplusone is off: it needs jq. Install it with `brew install jq` (macOS) or `sudo apt install jq` (Debian/Ubuntu). Other systems: https://jqlang.org/download/"}'
  exit 0
fi

input="$(cat)"
transcript="$(jq -r '.transcript_path // empty' <<<"$input")"
session="$(jq -r '.session_id // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"
[ -f "$transcript" ] || exit 0

# Only git repos get a doc.
repo="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || exit 0
gitdir="$(git -C "$repo" rev-parse --absolute-git-dir)"
mkdir -p "$gitdir/fourplusone/queue"

# Snapshot the turn now, while it is the latest one in the transcript.
turn="$gitdir/fourplusone/queue/$(date +%s)-$$-$session.txt"
"$(dirname "$0")/extract-turn.sh" "$transcript" "$session" >"$turn"
[ -s "$turn" ] || { rm -f "$turn"; exit 0; }

nohup "$(dirname "$0")/worker.sh" "$repo" "$gitdir" >>"$gitdir/fourplusone/log" 2>&1 &
disown
exit 0
