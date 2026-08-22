# Graphify macOS 安装与使用手册

更新日期：2026-08-22

官方仓库：[Graphify-Labs/graphify](https://github.com/Graphify-Labs/graphify)

## 1. 本机安装结果

- 系统：macOS 26.4，Apple Silicon（arm64）
- 安装方式：`uv tool` 隔离安装
- Graphify：`0.9.48`
- CLI：`/Users/fly/.local/bin/graphify`
- Codex skill：`/Users/fly/.codex/skills/graphify/SKILL.md`
- Codex 多代理功能：已在 `/Users/fly/.codex/config.toml` 中启用
- 验证结果：本地 AST 解析成功，测试图包含 2 个节点和 1 条关系

安装或修改 Codex 配置后，请重启 Codex，使 skill 和 `multi_agent` 配置生效。

## 2. 环境要求

Graphify 要求 Python 3.10 或更高版本，推荐使用 `uv` 隔离安装。macOS 可通过 Homebrew 准备环境：

```bash
brew install python@3.12 uv
python3 --version
uv --version
```

本机已经具备 Homebrew、Python 和 `uv`，不需要重复安装。

## 3. 安装 Graphify CLI

PyPI 官方包名是 `graphifyy`（两个 `y`），安装后的命令名是 `graphify`：

```bash
uv tool install graphifyy
```

验证安装：

```bash
command -v graphify
graphify --version
uv tool list
```

如果终端提示 `graphify: command not found`，运行：

```bash
uv tool update-shell
```

然后关闭并重新打开终端。`uv` 默认把命令安装到 `~/.local/bin`。

## 4. 注册到 Codex

安装用户级 Codex skill：

```bash
graphify install --platform codex
```

确认以下文件存在：

```bash
test -f ~/.codex/skills/graphify/SKILL.md && echo "Graphify skill 已安装"
```

Graphify 在 Codex 中进行并行提取时需要启用多代理功能。在现有 `~/.codex/config.toml` 的 `[features]` 段中加入这一行，不要创建重复的 `[features]` 段：

```toml
[features]
multi_agent = true
```

完成后重启 Codex。在 Codex 中使用 skill 的写法是：

```text
$graphify .
```

Graphify 的通用提示有时显示 `/graphify .`；Codex 使用 `$graphify`。

## 5. 基本使用

在准备分析的项目根目录打开 Codex，然后运行：

```text
$graphify .
```

也可以绕过助手，直接调用 CLI。只解析代码、完全本地运行且不需要 API key：

```bash
cd /path/to/project
graphify extract . --code-only
```

默认输出位于 `graphify-out/`：

```text
graphify-out/
├── graph.html
├── GRAPH_REPORT.md
└── graph.json
```

常用查询：

```bash
graphify query "认证流程涉及哪些模块？"
graphify path "入口节点" "目标节点"
graphify explain "节点名称"
```

增量更新已有图：

```bash
graphify update .
```

## 6. 隐私和可选能力

代码通过本地 tree-sitter AST 解析，不需要 LLM，源码不会因代码解析而上传。文档、PDF、图片、音视频的语义处理需要助手模型或配置的模型 API；使用这些能力前应根据数据敏感度选择后端。

常见可选依赖：

```bash
uv tool install "graphifyy[pdf]"       # PDF
uv tool install "graphifyy[office]"    # DOCX、XLSX
uv tool install "graphifyy[sql]"       # SQL schema
uv tool install "graphifyy[video]"     # 音视频转写
uv tool install "graphifyy[mcp]"       # MCP stdio server
uv tool install "graphifyy[chinese]"   # 中文查询分词
```

如果已安装基础版而 `uv` 提示工具已存在，可加 `--reinstall`：

```bash
uv tool install --reinstall "graphifyy[pdf,chinese]"
```

## 7. 升级

```bash
uv tool upgrade graphifyy
graphify install --platform codex
graphify --version
```

升级后重新运行安装命令，可同步更新 Codex skill 文件。重启 Codex 后再使用。

## 8. 卸载

先删除 Graphify 注册到助手平台的文件，再卸载 CLI：

```bash
graphify uninstall
uv tool uninstall graphifyy
```

如果还要清除项目生成的图数据，请在对应项目中确认内容不再需要后，再删除 `graphify-out/`。Graphify 也提供会同时清理输出的命令：

```bash
graphify uninstall --purge
```

`--purge` 会删除生成结果，执行前应先备份需要保留的 `graph.json`、报告或 HTML。

如果不再需要 Codex 多代理功能，可从 `~/.codex/config.toml` 删除 `multi_agent = true`；如果其他工具也依赖该功能，则应保留。

## 9. 常见问题

### 安装了错误的软件包

官方 PyPI 包是 `graphifyy`，不是 `graphify`。修复方式：

```bash
uv tool uninstall graphify
uv tool install graphifyy
```

### Codex 看不到 `$graphify`

依次检查：

```bash
graphify install --platform codex
test -f ~/.codex/skills/graphify/SKILL.md
```

确认安装成功后，完全退出并重新打开 Codex。

### 只想本地分析代码

使用 `--code-only`，不配置任何模型 API：

```bash
graphify extract . --code-only
```

### 输出目录不应提交到 Git

如果团队不打算版本化知识图谱，在项目 `.gitignore` 中加入：

```gitignore
graphify-out/
```

是否提交图数据取决于团队工作流；`graph.json` 可能包含源码符号、文件路径和关系信息，应按项目的数据分类规则处理。
