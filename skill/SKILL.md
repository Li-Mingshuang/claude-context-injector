# context-injector

自动向每条 Claude Code 对话注入上下文信息（时间、天气、Git 状态等）。
通过 `UserPromptSubmit` hook 实现，支持配置开关和自定义数据源。

触发词：`context-injector`、`配置上下文注入`、`查看注入内容`、`开启天气注入`、`添加自定义注入源`

---

## 工作流程

### Step 1：检测安装状态

```bash
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
SKILL_DIR="$HOME/.claude/skills/context-injector"
GATHER="$SKILL_DIR/bin/gather.sh"
CONFIG="$HOME/.claude-context-injector/config.json"
SETTINGS="$HOME/.claude/settings.json"

echo "GATHER_EXISTS=$([ -f "$GATHER" ] && echo yes || echo no)"
echo "CONFIG_EXISTS=$([ -f "$CONFIG" ] && echo yes || echo no)"
echo "HOOK_SET=$(jq -e '.hooks.UserPromptSubmit[]?.hooks[]?.command' "$SETTINGS" 2>/dev/null | grep -q "gather.sh" && echo yes || echo no)"
```

根据输出判断：
- `GATHER_EXISTS=no`：skill 未正确安装，告知用户把 skill 目录放到 `~/.claude/skills/context-injector/`
- `CONFIG_EXISTS=no`：首次运行，执行 **自动初始化**
- `HOOK_SET=no`：hook 未注册，执行 **注册 hook**

---

### Step 2：自动初始化（首次运行时）

**创建默认 config.json：**

```bash
mkdir -p "$HOME/.claude-context-injector"
cat > "$HOME/.claude-context-injector/config.json" << 'EOF'
{
  "time": true,
  "weather": false,
  "weather_location": "",
  "git": true,
  "battery": false,
  "cwd": false,
  "custom": []
}
EOF
echo "Config created"
```

**注册 UserPromptSubmit hook：**

```bash
python3 - <<'PYEOF'
import json, os
settings_path = os.path.expanduser("~/.claude/settings.json")
gather_path = os.path.expanduser("~/.claude/skills/context-injector/bin/gather.sh")
hook_cmd = f"bash {gather_path}"

settings = {}
if os.path.exists(settings_path):
    with open(settings_path) as f:
        settings = json.load(f)

settings.setdefault("hooks", {}).setdefault("UserPromptSubmit", [])

already = any(
    any(h.get("command") == hook_cmd for h in g.get("hooks", []))
    for g in settings["hooks"]["UserPromptSubmit"]
)

if not already:
    settings["hooks"]["UserPromptSubmit"].append({
        "hooks": [{"type": "command", "command": hook_cmd}]
    })
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2)
    print("Hook registered")
else:
    print("Hook already set")
PYEOF
```

初始化完成后告知用户：**重启 Claude Code 后生效**，并进入 Step 3。

---

### Step 3：展示当前状态

```bash
CONFIG="$HOME/.claude-context-injector/config.json"
echo "=== 当前配置 ==="
jq '.' "$CONFIG"
echo ""
echo "=== 现在会注入这些内容 ==="
bash "$HOME/.claude/skills/context-injector/bin/gather.sh" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data['hookSpecificOutput']['additionalContext'])
" 2>/dev/null || echo "（暂无注入内容，或 jq/python3 未安装）"
```

清楚展示：哪些开关是开的、当前实际会注入什么内容。

---

### Step 4：询问用户要做什么

用 AskUserQuestion 提供选项：

- A) 开关数据源（时间/天气/Git/电量/目录）
- B) 添加自定义注入源（运行任意命令，结果注入上下文）
- C) 查看注入效果（实时预览）
- D) 移除 hook（停止注入）
- E) 没问题了，退出

---

### Step 5A：开关数据源

读取当前 config，用 AskUserQuestion 让用户勾选要开启的项（multiSelect）：

选项：`time`、`weather`（需输入城市）、`git`、`battery`（macOS）、`cwd`

用户选择后：

```bash
# 示例：开启天气，设置城市为 Beijing
python3 - <<'PYEOF'
import json, os
path = os.path.expanduser("~/.claude-context-injector/config.json")
with open(path) as f:
    config = json.load(f)
config["weather"] = True
config["weather_location"] = "Beijing"  # 替换为用户输入的城市
with open(path, "w") as f:
    json.dump(config, f, indent=2)
print("已更新")
PYEOF
```

更新后立即运行一次 gather.sh 预览效果，确认注入内容符合预期。

---

### Step 5B：添加自定义注入源

询问用户：
1. **标签名**（如 `今日待办`、`CPU负载`）
2. **Shell 命令**（如 `task list | head -3`、`uptime | awk '{print $10}'`）

验证命令能正常执行且有输出后，写入 config：

```bash
python3 - <<'PYEOF'
import json, os
path = os.path.expanduser("~/.claude-context-injector/config.json")
with open(path) as f:
    config = json.load(f)
config.setdefault("custom", []).append({
    "label": "LABEL",      # 替换为用户输入
    "command": "COMMAND",  # 替换为用户输入
    "enabled": True
})
with open(path, "w") as f:
    json.dump(config, f, indent=2)
print("已添加")
PYEOF
```

---

### Step 5D：移除 hook

```bash
python3 - <<'PYEOF'
import json, os
settings_path = os.path.expanduser("~/.claude/settings.json")
gather_path = os.path.expanduser("~/.claude/skills/context-injector/bin/gather.sh")
hook_cmd = f"bash {gather_path}"

with open(settings_path) as f:
    settings = json.load(f)

hooks = settings.get("hooks", {}).get("UserPromptSubmit", [])
settings["hooks"]["UserPromptSubmit"] = [
    g for g in hooks
    if not any(h.get("command") == hook_cmd for h in g.get("hooks", []))
]

with open(settings_path, "w") as f:
    json.dump(settings, f, indent=2)
print("Hook 已移除，重启 Claude Code 生效")
PYEOF
```

---

## 安装方式

将 skill 目录复制到 Claude Code skills 路径：

```bash
cp -r skill/ ~/.claude/skills/context-injector
```

之后在 Claude Code 里说 `context-injector` 即可启动。

---

## 配置文件位置

`~/.claude-context-injector/config.json`

```json
{
  "time": true,
  "weather": false,
  "weather_location": "Beijing",
  "git": true,
  "battery": false,
  "cwd": false,
  "custom": [
    {
      "label": "自定义标签",
      "command": "your-command-here",
      "enabled": true
    }
  ]
}
```
