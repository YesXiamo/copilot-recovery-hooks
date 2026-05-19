#!/usr/bin/env bash
# install.sh — 一键把 copilot-recovery-hooks 部署到当前项目
#
# 用法:
#   curl -fsSL https://raw.githubusercontent.com/YesXiamo/copilot-recovery-hooks/main/install.sh | bash
#   ── 或 ──
#   git clone https://github.com/YesXiamo/copilot-recovery-hooks && cd copilot-recovery-hooks && ./install.sh /path/to/your/project

set -euo pipefail

TARGET="${1:-$PWD}"
RAW_BASE="${RAW_BASE:-https://raw.githubusercontent.com/YesXiamo/copilot-recovery-hooks/main}"
HOOKS=(
  auto-refine.sh
  budget-guard.sh
  checkpoint.sh
  failure-recorder.sh
  session-finalize.sh
  session-resume.sh
  shell-guard.sh
  tool-guard.sh
)

# ── 颜色 ──────────────────────────────────────────────
if [ -t 1 ]; then
  G="\033[32m"; Y="\033[33m"; R="\033[31m"; B="\033[34m"; N="\033[0m"
else
  G=""; Y=""; R=""; B=""; N=""
fi
say() { printf "${B}[install]${N} %s\n" "$*"; }
ok()  { printf "${G}  ✓${N} %s\n" "$*"; }
warn(){ printf "${Y}  ⚠${N} %s\n" "$*"; }
die() { printf "${R}  ✗${N} %s\n" "$*" >&2; exit 1; }

# ── 1) 检查依赖 ──────────────────────────────────────
say "检查依赖…"
for bin in bash jq shasum; do
  command -v "$bin" >/dev/null 2>&1 || die "缺少 $bin。macOS: brew install jq"
  ok "$bin 已安装"
done

# ── 2) 检查目标目录 ────────────────────────────────
[ -d "$TARGET" ] || die "目标目录不存在: $TARGET"
say "目标项目: $TARGET"

mkdir -p "$TARGET/.aone_copilot/hooks"
mkdir -p "$TARGET/.aone_copilot/state"
ok "目录骨架准备就绪"

# ── 3) 安装 hooks.json(已存在则备份) ────────────
HOOKS_JSON="$TARGET/.aone_copilot/hooks.json"
if [ -f "$HOOKS_JSON" ]; then
  bak="$HOOKS_JSON.bak.$(date +%s)"
  cp "$HOOKS_JSON" "$bak"
  warn "已有 hooks.json,备份到 $bak"
fi

# ── 4) 复制或下载文件 ──────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/hooks.json" ] && [ -d "$SCRIPT_DIR/hooks" ]; then
  say "本地模式:从仓库目录复制"
  cp "$SCRIPT_DIR/hooks.json" "$HOOKS_JSON"
  # 插件模式用 ./hooks/ 路径,手动安装模式用 .aone_copilot/hooks/ 路径
  sed -i "" "s|\./hooks/|.aone_copilot/hooks/|g" "$HOOKS_JSON"
  for h in "${HOOKS[@]}"; do
    cp "$SCRIPT_DIR/hooks/$h" "$TARGET/.aone_copilot/hooks/$h"
    chmod +x "$TARGET/.aone_copilot/hooks/$h"
    ok "hooks/$h"
  done
else
  say "远程模式:从 $RAW_BASE 下载"
  curl -fsSL "$RAW_BASE/hooks.json" -o "$HOOKS_JSON" || die "下载 hooks.json 失败"
  # 插件模式用 ./hooks/ 路径,手动安装模式用 .aone_copilot/hooks/ 路径
  sed -i "" "s|\./hooks/|.aone_copilot/hooks/|g" "$HOOKS_JSON"
  for h in "${HOOKS[@]}"; do
    curl -fsSL "$RAW_BASE/hooks/$h" -o "$TARGET/.aone_copilot/hooks/$h" || die "下载 $h 失败"
    chmod +x "$TARGET/.aone_copilot/hooks/$h"
    ok "hooks/$h"
  done
fi

# ── 5) 写 .gitignore ──────────────────────────────
GI="$TARGET/.gitignore"
touch "$GI"
if ! grep -q "^\.aone_copilot/state/" "$GI" 2>/dev/null; then
  printf "\n# copilot-recovery-hooks runtime state\n.aone_copilot/state/\n" >> "$GI"
  ok "已追加 .aone_copilot/state/ 到 .gitignore"
else
  ok ".gitignore 已有规则,跳过"
fi

# ── 6) 完成提示 ────────────────────────────────────
cat <<EOF

${G}═══════════════════════════════════════════════════${N}
${G} ✓ copilot-recovery-hooks 安装完成${N}
${G}═══════════════════════════════════════════════════${N}

下一步验证:
  1) 在 Aone Copilot 中打开此项目
  2) 顶部 → Copilot Hub → Hooks 标签
  3) 确认看到 8 个 hook 全部加载

测试自动恢复:
  让 Agent 跑一个故意失败的任务(例如执行不存在的脚本)
  观察 stop 后是否自动续发了反思消息

卸载:
  $SCRIPT_DIR/uninstall.sh $TARGET

文档:
  https://github.com/YesXiamo/copilot-recovery-hooks
EOF
