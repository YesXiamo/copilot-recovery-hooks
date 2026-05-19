#!/bin/bash
INPUT=$(cat)
SESSION=$(echo "$INPUT" | jq -r '.session_id')
F=".aone_copilot/state/budget-$SESSION.json"
COUNT=$(jq -r '.count // 0' "$F" 2>/dev/null || echo 0)
COUNT=$((COUNT + 1))
echo "{\"count\":$COUNT}" > "$F"

if [ "$COUNT" -gt 50 ]; then
  jq -n '{continue:false, user_message:"当前会话已达 50 轮预算上限,请新建会话或拆分任务。"}'
  exit 0
fi

echo '{"continue":true}'
exit 0
