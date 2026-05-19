#!/bin/bash
# Agent 循环结束时,根据失败日志决定是否自动续发触发 self-refine
INPUT=$(cat)
STATUS=$(echo "$INPUT" | jq -r '.status')
LOOP=$(echo "$INPUT" | jq -r '.loop_count')
TRACE=$(echo "$INPUT" | jq -r '.trace_id')

# 已经续发太多次,直接停止(避免烧钱)
if [ "$LOOP" -ge 2 ]; then
  echo '{}'
  exit 0
fi

FAIL_LOG=".aone_copilot/state/failures.jsonl"
[ -f "$FAIL_LOG" ] || { echo '{}'; exit 0; }

# 取本 trace 最近一次失败
LAST=$(grep "\"trace_id\":\"$TRACE\"" "$FAIL_LOG" | tail -1)
[ -z "$LAST" ] && { echo '{}'; exit 0; }

ERR=$(echo "$LAST" | jq -r '.error_message')
TYPE=$(echo "$LAST" | jq -r '.failure_type')   # error / timeout / permission_denied
TOOL=$(echo "$LAST" | jq -r '.tool_name')

# 不可恢复的失败不要续发
case "$TYPE" in
  permission_denied) echo '{}'; exit 0 ;;
esac

# 构造 Reflexion 续发消息
MSG="上一步 [${TOOL}] 因 [${TYPE}] 失败: ${ERR} 。请按以下顺序反思后再尝试:1) 真正的失败原因是什么 2) 是否应换用其他工具/参数 3) 任务能否拆得更小 4) 是否需要先获取更多上下文。给出方案后再执行。"

jq -n --arg m "$MSG" '{followup_message: $m}'
exit 0
