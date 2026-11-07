#!/usr/bin/env bash
# Processes queued turns one at a time per repo, oldest first, so two turns
# never write to fourplusone.md at the same moment.
set -euo pipefail
repo="$1"
gitdir="$2"
root="$(cd "$(dirname "$0")/.." && pwd)"
state="$gitdir/fourplusone"

# One worker per repo. If another holds the lock, it will pick up our turn.
mkdir "$state/lock" 2>/dev/null || exit 0
trap 'rmdir "$state/lock"' EXIT

# Keep the doc out of git without touching the team's .gitignore.
grep -qxF '/fourplusone.md' "$gitdir/info/exclude" 2>/dev/null ||
  { mkdir -p "$gitdir/info"; echo '/fourplusone.md' >>"$gitdir/info/exclude"; }

cd "$repo"
while turn="$(ls "$state/queue/"*.txt 2>/dev/null | sort | head -1)" && [ -n "$turn" ]; do
  echo "[$(date '+%F %T')] observing $(basename "$turn")"
  FOURPLUSONE_OBSERVER=1 claude -p \
    --model sonnet \
    --system-prompt "$(cat "$root/prompts/fourplusone.md")" \
    --tools "Read,Edit,Write,Glob,Grep" \
    --allowedTools "Read" "Glob" "Grep" "Edit(./fourplusone.md)" \
    --permission-mode dontAsk \
    --no-session-persistence \
    <"$turn" || echo "[$(date '+%F %T')] observer failed on $(basename "$turn")"
  rm -f "$turn"
done
