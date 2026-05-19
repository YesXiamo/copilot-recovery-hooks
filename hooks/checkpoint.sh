#!/bin/bash
INPUT=$(cat)
TRACE=$(echo "$INPUT" | jq -r '.trace_id')
DIR=".aone_copilot/state/checkpoints/$TRACE"
mkdir -p "$DIR"
TS=$(date +%s%N)
echo "$INPUT" > "$DIR/$TS.json"

# 滚动保留最近 50 步(避免膨胀)
ls -t "$DIR"/*.json 2>/dev/null | tail -n +51 | xargs -r rm 2>/dev/null
exit 0
