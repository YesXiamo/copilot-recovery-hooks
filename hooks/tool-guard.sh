#!/bin/bash
INPUT=$(cat)
TRACE=$(echo "$INPUT" | jq -r '.trace_id')
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
ARGS=$(echo "$INPUT" | jq -c '.tool_input')
KEY=$(printf '%s' "$TOOL$ARGS" | shasum -a 256 | awk '{print $1}')

DIR=".aone_copilot/state/loop"
mkdir -p "$DIR"
COUNTER="$DIR/$TRACE-$KEY"
COUNT=$(cat "$COUNTER" 2>/dev/null || echo 0)
COUNT=$((COUNT + 1))
echo "$COUNT" > "$COUNTER"

if [ "$COUNT" -gt 3 ]; then
  jq -n '{permission:"deny",
          user_message:"检测到工具循环,已熔断",
          agent_message:"检测到你正在重复调用同一工具同一参数。请换思路:或换工具,或拆子任务,或停止任务向用户求助。"}'
  exit 0
fi

echo '{"permission":"allow"}'
exit 0
