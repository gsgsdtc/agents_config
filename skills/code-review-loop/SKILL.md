---
name: code-review-loop
description: |
  此技能用于代码审查、修改、测试验证和提交 MR 的闭环流程。
  提供通用的 Review-Fix-Test-MR 循环，可独立使用或与其他 skill 配合。

  触发条件（匹配以下任一模式即使用此skill）：
  - "代码review" / "code review" / "审查代码"
  - "review后修改" / "review并修复" / "review-fix"
  - "代码审查循环" / "review loop" / "修复循环"
  - "集成测试修改" / "修复测试" / "测试验证"
  - "提交MR" / "创建MR" / "submit MR" / "create MR"
  - 用户要求对代码进行 review 后修改并验证

  关键词识别：代码review、code review、审查、修复、测试验证、review-fix、循环、MR、merge request
version: 0.1.0
---

# Code Review Loop

## 目的

提供一个抽象的、可复用的代码审查和修复循环流程：

```
┌─────────────────────────────────────────────────────────────┐
│                    Code Review Loop                          │
│                                                              │
│   ┌──────────┐     ┌──────────┐     ┌──────────┐           │
│   │  REVIEW  │────▶│   FIX    │────▶│   TEST   │           │
│   │  代码审查 │     │  代码修复 │     │  测试验证 │           │
│   └──────────┘     └──────────┘     └────┬─────┘           │
│        ▲                                  │                  │
│        │                                  │                  │
│        └──────────── 失败 ◀───────────────┘                  │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 适用场景

| 场景 | 说明 |
|------|------|
| 独立代码审查 | 对现有代码进行 review 后修复 |
| 设计实现后验收 | 配合 design-review-dev 使用 |
| 测试驱动修复 | 根据测试失败进行迭代修复 |
| CI/CD 集成 | 自动化 review-fix-test 流程 |

## 工作流

### 整体流程

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Code Review Loop                            │
└─────────────────────────────────────────────────────────────────────┘
         │
         ▼
┌─────────────────┐
│ 1) 输入分析     │ ◀── 确定 review 范围和标准
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2) 代码审查     │ ◀── 静态分析 + 人工审查
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3) 问题分类     │ ◀── 按严重程度分类
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4) 代码修复     │ ◀── 逐一修复问题
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 5) 测试验证     │ ◀── 回归测试确认修复
└────────┬────────┘
         │
    通过？
    ┌──┴──┐
    │     │
   YES    NO ──▶ 返回步骤 2
    │
    ▼
┌─────────────────┐
│ 5.5) Feature E2E│ ◀── 条件触发：feat 有页面或外部接口
└────────┬────────┘
         │
    通过？
    ┌──┴──┐
    │     │
   YES    NO ──▶ 返回步骤 4（修复问题）
    │
    ▼
┌─────────────────┐
│ 6) 输出报告     │
└────────┬────────┘
         │
    提交MR？
    ┌──┴──┐
    │     │
   YES    NO ──▶ 结束
    │
    ▼
┌─────────────────┐
│ 7) 提交 MR     │ ◀── git commit + push + 创建 MR
└─────────────────┘
```

### 1) 输入分析

确定审查范围和标准：

| 输入类型 | 处理方式 |
|----------|----------|
| 文件路径 | 直接审查指定文件 |
| 目录路径 | 递归审查目录下所有代码文件 |
| Git diff | 审查变更的代码 |
| 设计文档 | 根据设计要求审查实现 |
| 测试用例 | 根据测试要求审查代码 |

```bash
# 获取 review 范围
git diff --name-only HEAD~1  # 最近提交
git diff --name-only main..  # 相对主分支的变更
```

### 2) 代码审查

#### 2.1 静态分析

| 工具 | 检查内容 |
|------|----------|
| lint | 代码风格、格式 |
| typecheck | 类型安全 |
| security | 安全漏洞 |
| complexity | 代码复杂度 |

```bash
# Go 项目
make lint       # golangci-lint
make typecheck  # go vet

# Node.js 项目
npm run lint    # eslint
npm run typecheck  # tsc --noEmit

# Python 项目
make lint       # flake8/ruff
make typecheck  # mypy
```

#### 2.2 人工审查清单

| 审查维度 | 检查项 |
|----------|--------|
| 正确性 | 逻辑正确、边界处理、错误处理 |
| 安全性 | 输入验证、权限检查、敏感信息 |
| 性能 | 复杂度、资源使用、并发安全 |
| 可维护性 | 命名规范、代码结构、注释完整 |
| 测试覆盖 | 单元测试、边界测试、异常测试 |

### 3) 问题分类

按严重程度分类审查发现的问题：

| 级别 | 标识 | 说明 | 处理要求 |
|------|------|------|----------|
| Critical | 🔴 | 安全漏洞、数据丢失风险 | 必须立即修复 |
| Major | 🟠 | 功能错误、逻辑问题 | 必须修复 |
| Minor | 🟡 | 代码风格、命名问题 | 建议修复 |
| Info | 🔵 | 优化建议、改进点 | 可选修复 |

### 4) 代码修复

#### 4.1 修复优先级

```
修复顺序: 🔴 Critical → 🟠 Major → 🟡 Minor → 🔵 Info
```

#### 4.2 修复流程

```
┌─────────────────────────────────────────────────┐
│ 修复流程                                         │
├─────────────────────────────────────────────────┤
│                                                  │
│  1. 选择最高优先级问题                           │
│       │                                          │
│       ▼                                          │
│  2. 分析问题根因                                 │
│       │                                          │
│       ▼                                          │
│  3. 设计修复方案                                 │
│       │                                          │
│       ▼                                          │
│  4. 实施修复                                     │
│       │                                          │
│       ▼                                          │
│  5. 本地验证                                     │
│       │                                          │
│       ▼                                          │
│  6. 标记完成，继续下一个                         │
│                                                  │
└─────────────────────────────────────────────────┘
```

#### 4.3 修复记录

每个修复应记录：

```markdown
### 修复记录

| 问题ID | 级别 | 文件 | 问题描述 | 修复方案 | 状态 |
|--------|------|------|----------|----------|------|
| R-001 | 🔴 | auth.go:45 | SQL注入风险 | 使用参数化查询 | ✅ |
| R-002 | 🟠 | api.go:78 | 空指针未处理 | 添加nil检查 | ✅ |
```

### 5) 测试验证（回归验证，非 TDD）

> **重要区分**：新测试的编写属于 `design-review-dev`（开发阶段，TDD: RED→GREEN）。
> 本阶段**不写新测试**，只跑已有测试确保 review 修复没有引入回归。

#### 5.1 验证内容

| 验证类型 | 目的 | 命令示例 |
|----------|------|----------|
| 静态分析 | 修复后的代码质量门禁 | `make lint && make typecheck` |
| 全量单元测试 | 确保修复无副作用 | `make test` |
| 集成测试（如有） | 确保跨模块行为正常 | `make test-integration` |
| 覆盖率对比 | 修复不应降低覆盖率 | `go test -coverprofile` |

```bash
# 静态分析（必须）
make lint       # Go: golangci-lint / Node: eslint / Python: ruff
make typecheck  # Go: go vet / Node: tsc --noEmit / Python: mypy

# 全量回归测试（必须）
make test

# 集成测试（如有）
make test-integration
```

#### 5.2 通过标准

| 检查项 | 要求 |
|--------|------|
| Lint | 无新增错误 |
| TypeCheck | 无新增错误 |
| 全量测试 | 通过数 ≥ 修复前（不允许跳过或注释测试） |
| 覆盖率 | 不低于修复前水平 |

#### 5.3 失败处理

```
回归测试失败:
┌─────────────────┐
│ 测试失败        │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ 判断失败类型            │
│ ① 修复引入的回归 → 严重 │
│ ② 原本就失败的 → 记录   │
│ ③ 环境问题 → 排除       │
└────────┬────────────────┘
         │
    ┌────┴────┐
    │         │
  新回归    已有失败
    │         │
    ▼         ▼
  返回步骤4  记录到报告
  修复回归   （不阻塞流程）
```

**关键原则**：
- 修复引入的新回归 → **必须修复**，返回步骤 4
- 修复前就存在的失败 → **记录但不阻塞**，在报告中标注为"已有问题"
- **绝不允许**通过注释/跳过测试来"通过"验证

### 5.5) Feature E2E 验证（条件触发）

> **触发条件**：当前 feat 文档中包含**页面需求**或**外部接口需求**时触发。
> 如果 feat 只涉及内部逻辑变更（无页面、无外部接口），跳过此步。

#### 5.5.1 判断是否需要 Feature E2E

检查 feat 文档，识别以下标记：

| feat 包含 | 触发 E2E | 验证方式 |
|-----------|---------|---------|
| 页面/UI 需求 | ✅ 是 | agent-browser 操作页面 + 截图 |
| 外部 API 接口 | ✅ 是 | curl/httpie 按流程调用 |
| 仅内部逻辑 | ❌ 跳过 | 已被单元测试和回归测试覆盖 |

#### 5.5.2 执行流程

```
1. 读取 feat 文档的验收标准
       │
       ▼
2. 构造 E2E 测试步骤
   ├── API 类: 按验收标准组织 curl 调用序列
   └── UI 类:  按验收标准组织 agent-browser 操作序列
       │
       ▼
3. 执行并收集证据
   ├── API 响应: HTTP status + response body
   ├── 页面截图: agent-browser screenshot
   └── 页面内容: agent-browser get text / snapshot
       │
       ▼
4. AI 对比验收标准逐条判断
   ├── ✅ 符合 → 记录通过
   ├── ❌ 不符合 → 记录失败原因
   └── ⚠️ 无法判断 → 标记需人工确认
```

#### 5.5.3 AI 判断输出格式

```markdown
## Feature E2E 验证结果

Feat: docs/feat/feat-020-xxx.md

| 验收标准 | 结果 | 证据 |
|----------|------|------|
| 用户登录后能看到仪表盘 | ✅ | HTTP 200 + screenshot-01.png |
| 仪表盘显示最近 10 条记录 | ❌ 只有 8 条 | response: {"records": [...8 items]} |
| 点击记录跳转详情页 | ✅ | screenshot-02.png 显示详情内容 |

总结: 2/3 通过，1 项不符合
建议: 检查 dashboard API 的分页逻辑
```

#### 5.5.4 失败处理

- Feature E2E 失败 → **返回步骤 4（代码修复）**，根据 AI 分析的原因修复
- 修复后重新执行 Feature E2E
- 如果 AI 判断为"无法确定"，标记为需人工确认，**不阻塞流程**

### 6) 输出报告

#### 6.1 审查报告格式

```markdown
## Code Review Loop 报告

### 概要
- 审查范围：xxx
- 审查时间：xxx
- 发现问题：x 个
- 已修复：x 个
- 测试状态：✅/❌

### 问题统计
| 级别 | 数量 | 已修复 |
|------|------|--------|
| 🔴 Critical | x | x |
| 🟠 Major | x | x |
| 🟡 Minor | x | x |
| 🔵 Info | x | x |

### 修复详情
| 问题ID | 文件 | 问题 | 修复 | 状态 |
|--------|------|------|------|------|
| R-001 | xxx | xxx | xxx | ✅ |

### 测试结果
| 测试类型 | 状态 |
|----------|------|
| 单元测试 | ✅ |
| 集成测试 | ✅ |
| Lint | ✅ |
| TypeCheck | ✅ |

### 后续建议
- [ ] 合并 MR 到主分支
- [ ] 运行 /spec-sync 同步 Module Spec（保持活文档与代码同步）
```

### 7) 提交 MR

当所有检查通过后，可选择提交 Merge Request。

#### 7.1 前置检查

```bash
# 确认当前分支不是 main/master
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" == "main" || "$CURRENT_BRANCH" == "master" ]]; then
  echo "❌ 不允许在主分支上直接提交 MR，请先创建 feature 分支"
  exit 1
fi

# 确认 GITLAB_TOKEN 已设置
if [ -z "$GITLAB_TOKEN" ]; then
  echo "❌ 请先设置 GITLAB_TOKEN 环境变量"
  echo "参考: /gitlab-api 中的环境配置说明"
  exit 1
fi
```

#### 7.2 Git 提交与推送

```bash
# 查看变更
git status
git diff --stat

# 提交（消息包含 review 结果摘要）
git add -A
git commit -m "fix: code review fixes

- Critical: X fixed
- Major: X fixed
- Minor: X fixed
- All tests passing"

# 推送到远程
git push -u origin "$CURRENT_BRANCH"
```

#### 7.3 创建 GitLab MR

```bash
# 获取项目信息（复用 gitlab-api skill 的模式）
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
if [[ "$REMOTE_URL" =~ ^git@ ]]; then
  GITLAB_HOST=$(echo "$REMOTE_URL" | sed 's|^git@\([^:]*\):.*|\1|')
  PROJECT_PATH_RAW=$(echo "$REMOTE_URL" | sed 's|^git@[^:]*:||' | sed 's|\.git$||')
else
  GITLAB_HOST=$(echo "$REMOTE_URL" | sed 's|^https*://\([^/]*\)/.*|\1|')
  PROJECT_PATH_RAW=$(echo "$REMOTE_URL" | sed 's|^https*://[^/]*/||' | sed 's|\.git$||')
fi
PROJECT_PATH=$(echo "$PROJECT_PATH_RAW" | sed 's|/|%2F|g')

# 创建 MR
curl -s --request POST \
  --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  --data "{
    \"source_branch\": \"$CURRENT_BRANCH\",
    \"target_branch\": \"main\",
    \"title\": \"$MR_TITLE\",
    \"description\": \"$MR_DESCRIPTION\",
    \"remove_source_branch\": true
  }" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/merge_requests" \
  | jq '{iid, title, web_url, state}'
```

#### 7.4 MR 描述模板

MR 描述自动从审查报告生成：

```markdown
## Code Review Summary

### 问题统计
| 级别 | 发现 | 已修复 |
|------|------|--------|
| 🔴 Critical | X | X |
| 🟠 Major | X | X |
| 🟡 Minor | X | X |

### 关键修复
- [R-001] auth.go:45 - SQL注入风险 → 使用参数化查询
- [R-002] api.go:78 - 空指针未处理 → 添加nil检查

### 测试结果
- ✅ 单元测试通过
- ✅ 集成测试通过
- ✅ Lint 无错误
- ✅ TypeCheck 通过

### 关联
- Feat: docs/feat/xxx.md
- Design: docs/design/xxx-design.md
```

#### 7.5 交互确认

提交 MR 前**必须**向用户确认：

| 确认项 | 说明 |
|--------|------|
| MR 标题 | 展示生成的标题，用户可修改 |
| 目标分支 | 默认 main，用户可指定 |
| MR 描述 | 展示审查报告摘要 |
| Assignee | 可选，指定审核人 |
| Labels | 可选，添加标签 |

```
📝 即将创建 Merge Request:
  分支: feat/xxx → main
  标题: fix: code review fixes for feat-020
  描述: [审查报告摘要]

确认提交？ [Y/n]
```

## 与 ralph-loop 集成

当需要持续迭代修复时，可以启动 ralph-loop：

```bash
/ralph-loop:ralph-loop "执行 Code Review Loop:

📋 审查范围: <review_scope>
🎯 审查标准: lint + typecheck + 集成测试

循环流程:
1. 运行静态分析 (lint/typecheck)
2. 识别并分类问题
3. 逐一修复问题
4. 运行测试验证
5. 重复直到全部通过

验收标准:
- lint 无错误
- typecheck 通过
- 所有测试通过

Output <promise>REVIEW_COMPLETE</promise> when all checks pass." \
--completion-promise "REVIEW_COMPLETE" \
--max-iterations 10
```

## 命令用法

```bash
# 审查指定文件
/code-review-loop src/api/handler.go

# 审查最近提交
/code-review-loop --git-diff HEAD~1

# 审查相对主分支的变更
/code-review-loop --git-diff main..

# 配合设计文档审查
/code-review-loop --design docs/feat/020-design.md

# 配合测试用例审查
/code-review-loop --test docs/test/integration-test-001.md

# 审查 + 修复 + 提交 MR（全流程）
/code-review-loop --git-diff main.. --mr

# 仅提交 MR（跳过 review，用于已 review 完的代码）
/code-review-loop --mr-only
```

## 与其他 skill 的关系

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Skill 工作流                                │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│   gitlab-issue-intake                                                │
│         │                                                            │
│         ▼                                                            │
│   feat-review-design ──▶ 生成设计文档                               │
│         │                                                            │
│         ▼                                                            │
│   design-review-dev ──▶ 业务代码开发                                 │
│         │                                                            │
│         ▼                                                            │
│   code-review-loop ◀────── 可在任何阶段独立调用                      │
│         │                                                            │
│         ├──▶ ralph-loop:ralph-loop ──▶ 自动化测试循环               │
│         │                                                            │
│         ▼                                                            │
│   提交 MR ──▶ GitLab Merge Request（复用 gitlab-api）              │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```
