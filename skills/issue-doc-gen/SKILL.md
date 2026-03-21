---
name: issue-doc-gen
description: |
  将 GitLab issue 转化为结构化文档（需求文档/修复文档）。
  当用户要求"生成需求文档""生成修复文档""对齐需求""对齐 bug 根因"时使用。
  支持手动提供 issue 信息（无需 GitLab API）。
version: 1.2.0
---

# Issue Doc Gen

## 目的

将 issue 信息转化为结构化的开发文档：
- **Feat 类型**：生成需求文档（`docs/feat/feat-<iid>-<slug>.md`）
- **Bug 类型**：生成修复文档（`docs/modules/<module>/fix/fix-<iid>-<slug>.md`）

## 输入

此 skill 需要以下 issue 信息（可由 `gitlab-issue-intake` 提供，也可由用户手动提供）：

| 字段 | 必填 | 说明 |
|------|------|------|
| `iid` | Yes | Issue 编号 |
| `title` | Yes | Issue 标题 |
| `description` | Yes | Issue 描述（正文内容） |
| `labels` | No | 标签列表 |
| `web_url` | No | Issue 链接 |
| `state` | No | 状态（opened/closed） |
| `project` | No | 项目路径（从 git remote 推断） |

如果用户未通过 `gitlab-issue-intake` 获取数据，可以：
- 直接提供 issue 链接，由本 skill 提取关键信息
- 手动描述 issue 内容，由本 skill 整理为文档

## 工作流

### 0) 创建开发分支（必须）

在生成文档前，必须先创建开发分支：

```bash
# 检查是否在 git 仓库中
git rev-parse --is-inside-work-tree || echo "❌ 当前目录不是 git 仓库"

# 检查是否有未提交的改动
git diff --quiet && git diff --cached --quiet || echo "⚠️ 有未提交的改动，请先处理"

# 生成分支名（将标题转为 slug）
ISSUE_IID=<编号>
SLUG=$(echo "<issue标题>" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-' | sed 's/^-//;s/-$//' | cut -c1-50)

# 根据类型创建分支
# Bug 类型: fix/<iid>-<slug>
# Feat 类型: feat/<iid>-<slug>
git checkout -b "feat/${ISSUE_IID}-${SLUG}"  # 或 fix/...
```

**前置检查**：
- 若当前目录不是 git 仓库，提示用户切换目录
- 若有未提交改动，提示用户先处理（stash 或 commit）
- 若分支已存在，询问是否切换到该分支

### 1) 判断 Issue 类型

根据 issue 的标签和标题判断类型：

- **Bug 类型**：标签或标题包含 `bug`、`type::bug`、`kind/bug`、`修复`、`fix`
- **Feat 类型**：标签或标题包含 `feature`、`feat`、`enhancement`、`功能`、`需求`
- **无法判断**：询问用户确认类型

### 2) 识别受影响的 Feat（Bug 类型专用）

当 issue 为 Bug 类型时，需要识别该 bug 影响了哪些 feat：

**识别方法**：

1. **从 issue 描述中提取关键词**：
   - 分析 bug 涉及的模块、组件、功能名称
   - 提取相关的业务场景或用户流程

2. **搜索关联的 feat 文档**：
```bash
# 在 docs/feat/ 目录搜索相关的 feat 文档
ls docs/feat/ 2>/dev/null | head -20

# 根据关键词搜索 feat 文档内容
grep -l "<关键词>" docs/feat/*.md 2>/dev/null
```

3. **输出格式**：
```
📋 受影响的 Feat 文档：

| Feat ID | Feat 标题 | 文档位置 |
|---------|-----------|----------|
| 020 | 用户认证功能 | `docs/feat/feat-020-user-auth.md` |
| 035 | 数据导出功能 | `docs/feat/feat-035-data-export.md` |
```

4. **若无法确定**：
   - 列出可能相关的 feat 文档供用户确认
   - 询问用户该 bug 影响哪个功能模块

### 3) 生成文档

根据 issue 类型生成对应文档：

**Bug 类型**：
- 模板：`assets/fix-template.md`
- 输出路径：`docs/modules/<module>/fix/fix-<iid>-<slug>.md`（slug 从 issue 标题生成）
- **必须填充**：影响的模块和 Feat 信息（来自步骤 2）

**Feat 类型**：
- 模板：`assets/feat-template.md`
- 输出路径：`docs/feat/feat-<iid>-<slug>.md`

填充模板时替换以下占位符：
- `{iid}`：issue iid
- `{功能简述}` / `{问题简述}`：issue 标题
- `{date}`：当前日期
- `{source}`：issue 链接或来源
- `{priority}` / `{severity}`：优先级/严重程度
- `{模块名}`：所属模块（Bug 类型需要识别）

**文档内容要求**：
- 基于 issue 描述提取信息，填充模板各章节
- 信息不足的章节标记为"待补充"，不要编造内容
- 尽可能从 issue 描述中推断合理的内容

**Feat 文档内容边界（严格遵守）**：

Feat 文档是**需求文档**，只描述"做什么"和"为什么"，不描述"怎么做"。

| 允许写入 | 禁止写入 |
|----------|----------|
| 用户场景、业务流程 | 代码片段、伪代码 |
| 验收标准（可测试的行为描述） | API 设计、数据库 schema |
| 约束条件（技术限制） | 具体的技术方案、架构设计 |
| 非功能需求（性能指标等） | 函数签名、类定义、SQL |
| 依赖说明（需要哪个模块配合） | 实现步骤、代码修改清单 |

> 技术设计和代码实现属于下游 skill（feat-review-design → design-review-dev）的职责，
> feat 文档写入实现细节会导致需求与设计耦合，后续变更维护困难。

**自检规则**：生成 feat 文档后，检查是否包含以下内容并移除：
- `` ` `` 代码块（除非是用户操作示例的伪命令）
- `import`、`class`、`function`、`def`、`struct` 等代码关键字
- 文件路径 + 行号引用（如 `src/auth/handler.go:45`）
- "实现方案"、"技术方案"、"代码修改" 等章节标题

### 4) 对齐问题清单

**Bug 对齐要点**：
- 复现步骤是否清晰？
- 影响范围如何？
- **影响的 Feat 是否明确？**（必须关联到具体的 feat 文档）
- 根因是否有证据支撑？
- 修复方案是否可行？
- 风险与验证方案？

**Feat 对齐要点**：
- 目标与价值是否明确？
- 用户与场景是否清晰？
- 必须项与非目标是否区分？
- 约束与依赖是否识别？
- 验收标准是否可测？
- 优先级与时间是否合理？

### 6) 等待用户确认（必须）

**重要：此 skill 执行完成后必须停止，等待用户确认后再进行下一步！**

输出完成后，显示以下信息并等待用户响应：

```
════════════════════════════════════════════════════════════════
📋 文档已生成，请查看：

  [需求文档]
  - [Bug] docs/modules/<module>/fix/fix-<iid>-<slug>.md
  - [Feat] docs/feat/feat-<iid>-<slug>.md

⚠️  请检查以上对齐问题清单，确认文档内容是否完整准确。

❓ 确认后请告知：
   - 如有问题需要修改，请说明
   - 如果没有问题，回复"确认"或"ok"进入下一步
════════════════════════════════════════════════════════════════
```

**禁止行为**：
- 不得自动开始编码
- 不得跳过用户确认直接进入设计阶段
- 不得假设用户已确认

### 7) 下一步建议

用户确认文档无问题后，输出下一步建议：

**Feat 类型**：
```
✅ 需求文档已确认

📌 下一步：使用 feat-review-design skill 进行技术设计
   命令：/feat-review-design <文档路径>
   示例：/feat-review-design docs/feat/feat-123-user-auth.md
```

**Bug 类型**：
```
✅ 修复文档已确认

📌 下一步：使用 design-review-dev skill 进行设计 Review 后开发
   命令：/design-review-dev <文档路径>
   示例：/design-review-dev docs/modules/<module>/fix/fix-123.md
```

## 资源

- Bug 模板：`assets/fix-template.md`
- Feat 模板：`assets/feat-template.md`
