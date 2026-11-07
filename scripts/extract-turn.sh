#!/usr/bin/env bash
# Prints the latest turn of a Claude Code transcript as plain text:
# everything from the developer's last message to the end.
set -euo pipefail
transcript="$1"
session="$2"

echo "session: $session"
echo "time: $(date '+%Y-%m-%d %H:%M')"
echo

jq -rs '
  # A developer message is a user record whose content is text, not a tool result.
  def is_human: .type == "user" and (
    (.message.content | type) == "string" or
    ((.message.content | type) == "array" and any(.message.content[]; .type == "text"))
  );
  def cut: if (tostring | length) > 3000 then (tostring | .[0:3000]) + " …[cut]" else tostring end;

  map(select(.type == "user" or .type == "assistant"))
  | (map(is_human) | rindex(true)) as $start
  | if $start == null then empty else .[$start:] end
  | .[]
  | if is_human then
      "## developer\n" + (if (.message.content | type) == "string" then .message.content
                          else [.message.content[] | select(.type == "text") | .text] | join("\n") end)
    elif .type == "assistant" then
      .message.content[]
      | if .type == "text" then "## agent says\n" + .text
        elif .type == "tool_use" then "## agent runs " + .name + "\n" + (.input | tojson | cut)
        else empty end
    else
      .message.content[]
      | select(.type == "tool_result")
      | "## result\n" + (.content | if type == "array" then map(.text? // "") | join("\n") else tostring end | cut)
    end
' "$transcript"
