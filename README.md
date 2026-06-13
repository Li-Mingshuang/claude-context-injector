# claude-context-injector

自动向每条 Claude Code 对话注入上下文信息（时间、天气、Git 状态等）。

不用每次说"现在几点"、"我在哪个分支"——Claude 已经知道了。

## 效果演示

Claude 在处理你的消息前，已经悄悄收到了：

```
Current time: 2026-06-13 22:34:51 CST
Weather: Beijing: ⛅️ +28°C
Git: branch=main (3 uncommitted changes)
```

[→ 交互式课程说明](https://li-mingshuang.github.io/claude-context-injector/docs/course.html)

## 安装（推荐：Skill 方式）

```bash
git clone https://github.com/Li-Mingshuang/claude-context-injector
cp -r claude-context-injector/skill ~/.claude/skills/context-injector
```

然后在 Claude Code 里说：

```
context-injector
```

Claude 会自动完成 hook 注册和配置，**重启 Claude Code 后生效**。

## 安装（备选：手动脚本）

```bash
cd claude-context-injector
bash install.sh
```

## 支持的注入源

| 来源 | 示例 | 默认 |
|---|---|---|
| `time` | `Current time: 2026-06-13 22:34 CST` | ✅ 开 |
| `weather` | `Weather: Beijing: ⛅️ +28°C` | 关 |
| `git` | `Git: branch=main (3 uncommitted changes)` | ✅ 开 |
| `battery` | `Battery: 82% discharging` | 关 |
| `cwd` | `Working directory: /Users/you/project` | 关 |
| 自定义 | 任意 shell 命令的输出 | — |

## 配置

通过 Skill 交互式管理，或直接编辑 `~/.claude-context-injector/config.json`。

## 项目结构

```
skill/
├── SKILL.md          # Claude Code skill，包含安装、配置、管理的完整逻辑
└── bin/
    └── gather.sh     # UserPromptSubmit hook 调用的采集脚本
docs/
└── course.html       # 交互式课程说明页
install.sh            # 不使用 skill 时的备用安装脚本
```

## 要求

- Claude Code
- `jq`（`brew install jq`）
- `python3`
- `curl`（天气功能）

## License

MIT
