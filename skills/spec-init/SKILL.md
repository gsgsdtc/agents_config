---
name: spec-init
description: |
  初始化 spec 文档体系，支持 Epic 驱动和交互式问答兜底。
  当用户要求"初始化项目文档""创建 spec 体系""新项目 setup"或提供 Epic 文档时使用。

  触发条件：
  - "初始化 spec" / "创建项目文档" / "spec-init"
  - "新项目 setup" / "初始化项目"
  - 用户提供 Epic 文档并要求拆分模块

  关键词识别：初始化、spec、文档体系、Epic、模块划分、项目骨架
version: 0.2.0
---

# Spec Init

## 目的

初始化项目的 spec-driven 文档体系：
- 从 Epic 文档或交互式问答获取项目信息
- 解析并提议模块划分
- 生成 project-spec.md + module spec 骨架
- 可选生成 feat 文档或调用 project-init 生成代码骨架

## 输入

| 输入方式 | 说明 |
|---------|------|
| **Epic 文档**（推荐） | 用户提供 `.md` 文件或粘贴内容 |
| **交互式问答** | 用户没有 Epic，通过问答收集信息 |

### Epic 文档需要包含（越全越好）

| 信息 | 用途 | 必要性 |
|------|------|--------|
| 产品目标 | → project-spec §1 | 必须 |
| 用户角色/场景 | → 识别模块边界 | 必须 |
| 功能列表/用户故事 | → 拆分 feat + 识别模块 | 必须 |
| 非功能需求 | → 技术栈选型 + 全局约束 | 建议 |
| 技术偏好/限制 | → 技术栈 | 可选 |
| 外部系统集成 | → 边界模块识别 | 有就写 |

## 工作流

### 1) 获取项目信息

**方式 A：用户提供 Epic 文档**
- 读取 Epic 文档内容
- 解析项目目标、用户场景、功能列表

**方式 B：交互式问答**
```
📋 项目基本信息
  项目名称: ___________
  Git 仓库: ___________

🏗️ 项目类型
  ○ 后台管理系统 (Admin)
  ○ API 服务 (API)
  ○ 全栈应用 (Fullstack)
  ○ 纯前端 (Frontend)
  ○ 微服务 (Microservice)

🎨 前端: React + Ant Design Pro / React + Next.js / Vue + Element Plus / 不需要
⚙️ 后端: Go + Gin / Python + Flask / Python + FastAPI / Java + Spring Boot / Node + Express
💾 数据库: PostgreSQL / MySQL / SQLite / MongoDB
🚀 CI/CD: GitLab CI / GitHub Actions / 不需要
```

### 2) 解析 Epic / 分析需求

**提取关键信息**：
- **名词提取** → 数据域（实体）
- **动词提取** → 功能域（能力）
- **外部系统** → 边界模块（集成点）

**示例分析**：
```
输入："做一个工作流自动化平台。用户注册登录后，可以通过拖拽创建 DAG 工作流，
      设置定时触发或 Webhook 触发，执行结果可以在仪表盘查看。"

名词提取 → 用户、工作流、DAG、触发器、执行结果、仪表盘
动词提取 → 注册登录、创建拖拽、设置触发、执行、查看

按业务域分组：
┌──────────────┬───────────────────────────────┐
│ auth         │ 用户、注册登录                  │
│ workflow     │ DAG、创建拖拽、工作流定义        │
│ trigger      │ 定时触发、Webhook 触发          │
│ execution    │ 执行、执行结果                  │
│ dashboard    │ 仪表盘、查看                    │
└──────────────┴───────────────────────────────┘
```

### 3) 提议模块划分

基于分析结果，输出模块划分建议：

```
📋 模块划分建议（基于 Epic 分析）

| 模块 | 职责 | 建议目录 |
|------|------|---------|
| auth | 认证鉴权、用户管理 | internal/auth |
| workflow | DAG 工作流编排定义 | internal/workflow |
| trigger | 定时/Webhook 触发策略 | internal/trigger |
| execution | 工作流执行引擎 | internal/execution |
| dashboard | 数据可视化仪表盘 | internal/dashboard |

❓ 确认问题：
1. trigger 和 workflow 要合并为一个模块吗？
2. 技术栈偏好？（后端 Go/Python/Java，前端 React/Vue）
```

等待用户确认或调整模块划分。

### 4) 生成文档

用户确认模块划分后，生成以下文档：

#### 4.1 Project Spec

**路径**：`docs/spec/project-spec.md`

**使用模板**：`assets/project-spec-template.md`

**填充内容**：
- 项目目标（来自 Epic）
- 技术栈（来自用户选择）
- 模块划分表（Step 3 确认结果）
- 全局约束（性能/安全/兼容性要求）

#### 4.2 Module Specs

**路径**：`docs/modules/<module>/spec.md`

**使用模板**：`assets/module-spec-template.md`

为每个模块生成 spec 骨架：
- 模块职责（一句话描述）
- 功能列表（从 Epic 提取的该模块相关功能）
- 数据模型（占位符，待后续填充）
- 对外接口（占位符，待后续填充）

```bash
# 创建模块目录
mkdir -p docs/modules/{auth,workflow,trigger,execution,dashboard}

# 生成 module spec
touch docs/modules/auth/spec.md
touch docs/modules/workflow/spec.md
# ...
```

#### 4.3 Main Flows

**路径**：`docs/spec/main-flows.md`

**使用模板**：`docs/template-main-flows.md`

**生成时机**：无论 Epic 驱动还是交互式问答，都生成骨架。

**填充内容**：从 Epic 或问答信息中识别端到端的核心用户旅程，生成初始主流程列表。每个流程只填写标题和简述，步骤留空待开发后补充。

```markdown
示例骨架：

| ID | 主流程 | 优先级 | 状态 |
|----|--------|--------|------|
| MF-001 | 用户注册→登录→进入系统 | P0 | ⏳ 待补充 |
| MF-002 | 创建工作流→触发执行→查看结果 | P0 | ⏳ 待补充 |
| MF-003 | 管理员管理用户权限 | P1 | ⏳ 待补充 |
```

**识别规则**：
- P0：覆盖用户最核心的端到端路径（注册/登录、核心业务操作）
- P1：覆盖重要但非关键的完整路径
- 不需要穷举，5-10 条即可，宁少勿滥

#### 4.4 可选：拆分 Feat 文档

如 Epic 包含明确的功能列表，可拆分 feat 文档：

**路径**：`docs/feat/feat-{编号}-{slug}.md`

**使用模板**：参考 `issue-doc-gen/assets/feat-template.md`

```
📋 从 Epic 拆分出的 Feat 文档：

| 编号 | 功能 | 文档路径 |
|------|------|----------|
| 001 | 用户注册登录 | docs/feat/feat-001-user-auth.md |
| 002 | OAuth 第三方登录 | docs/feat/feat-002-oauth-login.md |
| ... | ... | ... |
```

### 5) 可选：调用 project-init

询问用户是否需要生成代码骨架：

```
❓ 是否需要生成项目代码骨架？
   这将调用 project-init skill，根据技术栈生成：
   - 项目目录结构
   - 基础代码（路由、配置、中间件）
   - CI/CD 配置
   - Dockerfile / docker-compose
```

如用户确认，调用 `/project-init` 继续。

### 6) 输出总结

```
════════════════════════════════════════════════════════════════
✅ Spec 文档体系初始化完成

📁 生成的文档：
  📄 docs/spec/project-spec.md          ← 项目全局规格
  📄 docs/spec/main-flows.md            ← 主流程骨架（P0/P1 流程列表）
  📄 docs/modules/auth/spec.md          ← 认证模块规格
  📄 docs/modules/workflow/spec.md      ← 工作流模块规格
  ...

  📄 docs/feat/feat-001-xxx.md          ← 需求文档（如拆分）

📌 下一步建议：
  1. 查看 project-spec.md，确认整体架构
  2. 查看 main-flows.md，确认主流程列表是否完整
  3. 按需调整各模块的 module spec
  4. 选择 feat 文档，使用 feat-review-design 进行详细设计
     命令：/feat-review-design docs/feat/feat-001-xxx.md

⚠️ 注意事项：
  - module spec 是活文档，开发完成后会通过 spec-sync 自动回写
  - main-flows.md 的流程步骤在各 feat 开发完成后由 spec-sync 逐步补充
  - 新增模块时重新运行 /spec-init
════════════════════════════════════════════════════════════════
```

## 目录结构

初始化后的文档目录结构：

```
docs/
├── spec/
│   ├── project-spec.md              ← 项目全局规格
│   └── main-flows.md                ← 主流程骨架（待开发后逐步填充）
├── modules/
│   ├── auth/
│   │   ├── spec.md                  ← 模块规格（活文档）
│   │   ├── design/                  ← 设计文档（待生成）
│   │   └── fix/                     ← 修复文档（待生成）
│   ├── workflow/
│   │   ├── spec.md
│   │   ├── design/
│   │   └── fix/
│   └── ...
└── feat/                            ← 需求文档（如拆分）
    ├── feat-001-xxx.md
    └── feat-002-xxx.md
```

## 资源

- Project Spec 模板：`assets/project-spec-template.md`
- Module Spec 模板：`assets/module-spec-template.md`
