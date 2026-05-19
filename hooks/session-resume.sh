#!/bin/bash
INPUT=$(cat)
TRACE=$(echo "$INPUT" | jq -r '.trace_id')
CKPT_DIR=".aone_copilot/state/checkpoints/$TRACE"

[ -d "$CKPT_DIR" ] || { echo '{}'; exit 0; }

DONE=$(ls "$CKPT_DIR" 2>/dev/null | wc -l | tr -d ' ')
LAST=$(ls -t "$CKPT_DIR" 2>/dev/null | head -1)
[ -z "$LAST" ] && { echo '{}'; exit 0; }

LAST_TOOL=$(jq -r '.tool_name // "(unknown)"' "$CKPT_DIR/$LAST")
LAST_INPUT=$(jq -c '.tool_input // {}' "$CKPT_DIR/$LAST")

CTX=$(jq -n --arg t "$TRACE" --arg n "$DONE" --arg lt "$LAST_TOOL" --arg li "$LAST_INPUT" \
  '"## 上次会话恢复\n本 trace (\($t)) 已完成 \($n) 步,最近一步工具=\($lt),参数=\($li)。\n请先复述目标,然后从中断点继续,不要重做已完成的步骤。"')

jq -n --argjson c "$CTX" '{additional_context: $c}'
