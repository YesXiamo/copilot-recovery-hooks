#!/bin/bash
INPUT=$(cat)
SESSION=$(echo "$INPUT" | jq -r '.session_id')
mkdir -p .aone_copilot/state/sessions
echo "$INPUT" > ".aone_copilot/state/sessions/$SESSION.json"
exit 0
