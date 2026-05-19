#!/bin/bash
INPUT=$(cat)
mkdir -p .aone_copilot/state
TS=$(date '+%Y-%m-%dT%H:%M:%S')
jq -c --arg ts "$TS" '. + {recorded_at: $ts}' <<< "$INPUT" \
  >> .aone_copilot/state/failures.jsonl
exit 0
