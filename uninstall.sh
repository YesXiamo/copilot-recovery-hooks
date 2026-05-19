#!/usr/bin/env bash
# uninstall.sh — 从项目中移除 copilot-recovery-hooks
set -euo pipefail

TARGET="${1:-$PWD}"
HOOKS=(
  auto-refine.sh budget-guard.sh checkpoint.sh failure-recorder.sh
  session-finalize.sh session-resume.sh shell-guard.sh tool-guard.sh
)

if [ -t 1 ]; then G="\033[32m"; Y="\033[33m"; N="\033[0m"; else G=""; Y=""; N=""; fi

printf "${Y}[uninstall]${N} 目标项目: %s\n" "$TARGET"

# 1) 移除 hook 脚本(保留 hooks.json,可手动删,因为可能被改过)
for h in "${HOOKS[@]}"; do
  f="$TARGET/.aone_copilot/hooks/$h"
  [ -f "$f" ] && rm "$f" && printf "  ✓ removed hooks/%s\n" "$h"
done

# 2) state/ 保留(用户可能想留历史),提示用户
if [ -d "$TARGET/.aone_copilot/state" ]; then
  printf "${Y}  state/ 目录已保留(含 checkpoints/失败流水/会话尾态)${N}\n"
  printf "  如要彻底清空: rm -rf %s/.aone_copilot/state\n" "$TARGET"
fi

# 3) hooks.json 保留(可能用户自定义过)
if [ -f "$TARGET/.aone_copilot/hooks.json" ]; then
  printf "${Y}  hooks.json 已保留(可能含自定义)${N}\n"
  printf "  如要清空: rm %s/.aone_copilot/hooks.json\n" "$TARGET"
fi

printf "${G}[uninstall] done${N}\n"
