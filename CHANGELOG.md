# Changelog

## [0.1.0] — 2026-05-19

### Added
- 初始版本,8 个 hook 脚本实现 5 层恢复模型
  - `auto-refine.sh` — L3 Reflexion 自动续发(stop hook)
  - `session-resume.sh` — L4 跨会话断点续传(sessionStart)
  - `checkpoint.sh` — L4 步骤级状态落盘
  - `session-finalize.sh` — L4 会话尾态持久化
  - `failure-recorder.sh` — L2 失败结构化记录
  - `tool-guard.sh` — L2 工具循环熔断
  - `shell-guard.sh` — L5 破坏性命令拦截
  - `budget-guard.sh` — L1 会话预算上限
- `install.sh` — 一键安装(支持 curl pipe / 本地目录两种模式)
- `uninstall.sh` — 安全卸载(保留 state 与自定义 hooks.json)
- `examples/` — 三种预设配置变体
- 中文 locale 下 bash 变量插值的修复(踩坑实录见 README)
