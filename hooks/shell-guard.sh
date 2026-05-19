#!/bin/bash
INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.command')

jq -n --arg c "$CMD" \
  '{permission:"deny",
    user_message:"检测到破坏性命令,需人工确认: \($c)",
    agent_message:"该命令(\($c))为高风险操作,我已自动阻止。请先与用户对齐,得到明确确认后再执行;或考虑更安全的替代方案。"}'
