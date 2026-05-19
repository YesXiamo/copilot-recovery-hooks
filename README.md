# copilot-recovery-hooks

> **8 个 hook 脚本,让 Aone Copilot Agent 出错自己爬起来。**

为 [Aone Copilot](https://yuque.alibaba-inc.com/copilot/userguide) 设计的自动恢复机制插件,通过其 Hook 系统在 Agent 生命周期关键点注入:

- L1 — 会话预算上限
- L2 — 工具循环熔断、失败结构化记录
- L3 — **Reflexion 自动反思续发**(`stop` hook + `loop_limit=3`)
- L4 — **跨会话断点续传**(`sessionStart` hook 读历史 checkpoint)
- L5 — 破坏性命令拦截

无需改 Aone Copilot 内核,纯配置 + bash 脚本。

---

## Quick Start

### 方式一:一键远程安装(推荐)

```bash
cd /path/to/your/project
curl -fsSL https://raw.githubusercontent.com/YesXiamo/copilot-recovery-hooks/main/install.sh | bash
```

### 方式二:克隆后安装

```bash
git clone https://github.com/YesXiamo/copilot-recovery-hooks.git
cd copilot-recovery-hooks
./install.sh /path/to/your/project
```

### 验证

1. 打开 Aone Copilot → **Copilot Hub** → **Hooks** 标签
2. 确认 8 个 hook 全部加载
3. 让 Agent 跑一个故意失败的任务,观察 `stop` 后是否自动续发反思消息

### 卸载

```bash
./uninstall.sh /path/to/your/project
```

---

## 依赖

- `bash` ≥ 4(macOS 自带 3.x 也能跑,但建议 brew 装 4+)
- `jq`(`brew install jq`)
- `shasum`(macOS 自带)

---

## 工作原理

### Hook 与 Aone Copilot 14 个生命周期事件的对应

```
事件                     脚本                       恢复层 / 用途
─────────────────────── ─────────────────────── ─────────────────
beforeSubmitPrompt   →  budget-guard.sh         L1 单会话超 50 轮拒发
preToolUse           →  tool-guard.sh           L2 同 (tool, args) 重复 ≥4 次熔断
postToolUse          →  checkpoint.sh           L4 每步状态落盘
afterFileEdit        →  checkpoint.sh           L4 文件级 checkpoint
postToolUseFailure   →  failure-recorder.sh     L2 失败写 jsonl
beforeShellExecution →  shell-guard.sh          L5 rm -rf/DROP 等命令拦截
sessionStart         →  session-resume.sh   ⭐ L4 注入"上次跑到第 N 步"
sessionEnd           →  session-finalize.sh     L4 会话尾态持久化
stop                 →  auto-refine.sh      ⭐ L3 followup_message 反思续发
```

### 状态目录布局

```
your-project/
├── .aone_copilot/
│   ├── hooks.json          ← 安装时写入
│   ├── hooks/              ← 8 个脚本
│   └── state/              ← 运行时状态(已自动加 .gitignore)
│       ├── checkpoints/<trace_id>/
│       ├── failures.jsonl
│       ├── budget-<sess>.json
│       ├── loop/
│       └── sessions/
```

### 两条关键流程

**1. 工具失败 → 自动反思续发**

```
工具失败  →  postToolUseFailure  →  failures.jsonl
                                            │
Agent 推理后 stop  →  auto-refine.sh  ←──┘
                            │
                            └→ followup_message: "上一步 [Shell] 因 [timeout] 失败: ... 请反思..."
                                       │
                                       ↓ 自动续发(受 loop_limit=3 限制)
                            Agent 进入新一轮带反思的循环
```

**2. 跨会话断点续传**

```
Day 1: trace=tr-X, session=s1
   ├ Step1 → checkpoint.sh → state/checkpoints/tr-X/1779.json
   ├ Step2 → checkpoint.sh → 1780.json
   ├ Step3 → checkpoint.sh → 1781.json
   └ IDE 崩溃 / 用户关机

Day 2: trace=tr-X, session=s2
   └ sessionStart → session-resume.sh
                       └→ additional_context:
                          "已完成 3 步,最近一步 = Shell test,请从中断点继续"
```

---

## 自定义配置

### 切到预设变体

`examples/` 目录提供三种预设:

| 预设 | 用途 |
|---|---|
| `minimal.json` | 最小集,只开 L3 反思 + L4 checkpoint。先尝鲜用 |
| `strict.json`(默认) | 全开,5 层都生效 |
| `observe-only.json` | 只观测不拦截,先开三天看故障分布 |

切换:把对应文件内容覆盖到 `.aone_copilot/hooks.json` 即可,Copilot 会热加载,无需重启 IDE。

### 改阈值

| 想调 | 改哪里 |
|---|---|
| 会话预算上限(默认 50 轮) | `hooks/budget-guard.sh` 第 9 行 `if [ "$COUNT" -gt 50 ]` |
| 工具循环熔断阈值(默认 3) | `hooks/tool-guard.sh` 第 16 行 `if [ "$COUNT" -gt 3 ]` |
| 反思续发上限(默认 3) | `hooks.json` 中 `stop` 的 `loop_limit` 字段 |
| 破坏性命令黑名单 | `hooks.json` 中 `beforeShellExecution` 的 `matcher` 正则 |
| Checkpoint 保留数量(默认 50) | `hooks/checkpoint.sh` 末行 `tail -n +51` |

---

## 已知坑

### 中文 locale 下 bash 变量插值

macOS 默认 `LANG=zh_CN.UTF-8`,bash 把高位字节(`E3..` 等中文)当字母,导致:

```bash
ERR="some error"
MSG="失败:$ERR。请重试"   # ❌ $ERR。 被当成变量名,展开成空
MSG="失败:${ERR} 。请重试" # ✅ 用 ${} 强制定界
```

本插件的 `auto-refine.sh` 已按此规范修复。如果你自己改脚本,**中文字符串里的变量一律 `${VAR}`**。

### 其他

- **Hook 子进程开销**:每个工具调用前后跑 hook 增加 50–100ms。关键路径用 `timeout: 5`。
- **`stop` 不能强制暂停**:只能续发或放行。要等人改用 `preToolUse` 拒绝。
- **`postToolUseFailure` 没有输出字段**:只能审计,改写要走 `stop`。
- **状态文件非事务性**:多 hook 并发写可能破损。生产换 sqlite/redis。
- **`state/` 必须进 `.gitignore`**:install.sh 已自动追加。

---

## 灵感来源

- [obra/superpowers](https://github.com/obra/superpowers) — Claude Code 的 skills 插件,启发了"用配置注入而非改内核"的设计思路。
- [Reflexion](https://arxiv.org/abs/2303.11366) — Shinn et al., 2023。`auto-refine.sh` 是其工程化简化版。
- [LangGraph Checkpoint](https://langchain-ai.github.io/langgraph/concepts/persistence/) — `checkpoint.sh` + `session-resume.sh` 的状态模型借鉴。
- [Anthropic — Scaling Managed Agents](https://www.anthropic.com/engineering/scaling-managed-agents) — Brain/Hands 解耦的"无状态 Harness + 可恢复 Session"思想。

---

## License

MIT © 2026 YesXiamo
