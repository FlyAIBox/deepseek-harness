---
type: "query"
date: "2026-08-24T14:43:41.414711+00:00"
question: "scratch-plugin/src/my-plugin.ts 找不到模块 @deepseek-ai/dsh-tools 或其相应的类型声明"
contributor: "graphify"
outcome: "useful"
source_nodes: ["tools/package.json", "tools/src/index.ts"]
---

# Q: scratch-plugin/src/my-plugin.ts 找不到模块 @deepseek-ai/dsh-tools 或其相应的类型声明

## Answer

Expanded from original query via graph vocab: [tools, tool, registry, definition, consumer, package]. The package exists at packages/core/tools. scratch-plugin/tsconfig.json overrides the inherited paths map with only @deepseek-ai/cordis, so TypeScript cannot resolve @deepseek-ai/dsh-tools. Adding a mapping from @deepseek-ai/dsh-tools to ../packages/core/tools makes the exact tsc repro pass with zero diagnostics.

## Outcome

- Signal: useful

## Source Nodes

- tools/package.json
- tools/src/index.ts