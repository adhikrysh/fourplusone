# Contributing

Issues and pull requests are welcome.

## Where things live

- `hooks/hooks.json` registers the Claude Code `Stop` hook.
- `scripts/observe.sh` runs on every turn end. It snapshots the turn into `.git/fourplusone/queue/` and starts the worker in the background.
- `scripts/extract-turn.sh` turns the transcript's latest turn into plain text.
- `scripts/worker.sh` feeds queued turns, oldest first, to `claude -p --model sonnet`, one worker per repo.
- `prompts/fourplusone.md` is the observer's system prompt. Most changes to what ends up in `fourplusone.md` belong here.

## Running your local copy

Load the plugin straight from your checkout instead of the marketplace:

```bash
claude --plugin-dir /path/to/fourplusone
```

Uninstall the marketplace version first so the hook doesn't run twice. Work in any git repo, end a turn, and watch `fourplusone.md` appear. If it doesn't, read `.git/fourplusone/log` in that repo.

## Pull requests

- Keep each PR to one change and say why it's needed.
- For prompt changes, include a before-and-after excerpt of `fourplusone.md` from a real session.
- Scripts are bash with `set -euo pipefail` and depend only on `git`, `jq`, and `claude`. Keep it that way.

## Reporting bugs

Use the bug report template. Include your OS, `claude --version`, `jq --version`, and the relevant lines of `.git/fourplusone/log`.

## Conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).
