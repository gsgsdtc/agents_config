---
name: project-init
description: |
  一站式项目初始化：代码骨架生成 + spec 文档体系初始化。
  触发: 初始化项目/创建项目/project-init/初始化spec/创建文档体系/新项目setup

  关键词：项目初始化、project init、骨架、scaffold、spec、文档体系、Epic、模块划分
version: 1.0.0
---

# Project Init

## 目的

一站式项目初始化，支持两种维度组合：
- **代码骨架**：生成项目目录、基础代码、配置、CI/CD
- **spec 文档体系**：生成 project-spec.md + module specs + main-flows.md

## 模式

| 模式 | 代码骨架 | spec 文档 | 适用场景 |
|------|---------|----------|---------|
| `code-admin` | Flask API | — | 后台 API 服务 |
| `code-api` | Go/Gin 或 Python/FastAPI | — | API 服务 |
| `code-fullstack` | 后端 + ui-gen 前端 | — | 全栈应用 |
| `code-microservice` | Go/Node 多模块 | — | 微服务 |
| `spec` | — | ✅ | 纯文档初始化 |
| `full` | ✅ | ✅ | 完整项目启动 |

---

## 工作流

### 入口：模式选择

```
🏗️ 项目初始化

请选择模式：
  [1] code-admin     - Flask API 后台
  [2] code-api       - Go/Python API 服务
  [3] code-fullstack - 全栈（后端 + ui-gen 前端）
  [4] code-microservice - 微服务
  [5] spec           - 仅初始化 spec 文档体系
  [6] full           - 完整初始化（代码骨架 + spec 文档）

📝 项目名称（英文小写）: my-project
```

`code-*` / `full` 模式追加技术栈选择：

```
[code-admin] 数据库: PostgreSQL / MySQL / SQLite
[code-api]   语言: Go / Python | 框架: Gin / FastAPI
[code-fullstack] 框架: Next.js / Nuxt | 数据库: PostgreSQL / Supabase
[code-microservice] 语言: Go / Node
```

---

## A. 代码骨架生成（code-* / full）

### A1. 项目结构

从模板目录生成，各模式结构见 `templates/<mode>/`：

| 模式 | 模板目录 | 关键目录 |
|------|---------|---------|
| code-admin | `templates/admin/` | backend/{app,api,models,services}, migrations/, tests/ |
| code-api (Go) | `templates/api/go/` | cmd/, internal/{handler,service,repository,model}, pkg/ |
| code-api (Python) | `templates/api/python/` | app/{api,core,models,schemas,services}, alembic/ |
| code-fullstack | `templates/fullstack/` | src/{app,components,lib,hooks}, prisma/ |
| code-microservice | `templates/microservice/` | services/{name}/{cmd,internal,pkg} |

### A2. 基础代码

生成内容：统一响应封装、错误处理中间件、数据库连接、JWT 认证中间件、CRUD 示例、健康检查。

日志配置（所有模式均生成）：`.env` 中配置 LOG_LEVEL/LOG_OUTPUT/LOG_FILE_PATH/LOG_MAX_SIZE/LOG_MAX_BACKUPS/LOG_MAX_AGE，各语言实现见 `templates/common/logging/`（Go Zap / Python loguru / Flask logging）。

> 日志规范：所有 POST/PUT/PATCH/DELETE 接口必须在入口打印请求参数、出口打印响应结果和耗时。

### A3. 部署配置

Dockerfile / docker-compose / CI/CD 从 `templates/<mode>/cicd/` 读取生成。

### A4. Makefile

从 `templates/<mode>/` 读取，包含 run/dev/test/build/docker/migrate 等 target。

---

## B. Spec 文档初始化（spec / full）

### B1. 获取项目信息

**方式 A：用户提供 Epic 文档**（推荐）

Epic 需包含：

| 信息 | 用途 | 必要性 |
|------|------|--------|
| 产品目标 | → project-spec §1 | 必须 |
| 用户角色/场景 | → 识别模块边界 | 必须 |
| 功能列表/用户故事 | → 拆分 feat + 识别模块 | 必须 |
| 非功能需求 | → 技术栈选型 + 全局约束 | 建议 |
| 外部系统集成 | → 边界模块识别 | 有则填 |

**方式 B：交互式问答**

```
📋 项目基本信息
  项目名称: ___________
  Git 仓库: ___________

🏗️ 项目类型
  ○ 后台管理系统 / API 服务 / 全栈应用 / 纯前端 / 微服务

🎨 前端: React + Next.js / Vue / 不需要
⚙️ 后端: Go + Gin / Python + FastAPI / Java + Spring Boot / Node + Express
💾 数据库: PostgreSQL / MySQL / SQLite / MongoDB
🚀 CI/CD: GitLab CI / GitHub Actions / 不需要
```

### B2. 解析 + 模块划分

**名词提取** → 数据域（实体）
**动词提取** → 功能域（能力）
**外部系统** → 边界模块（集成点）

示例：
```
输入："工作流自动化平台。用户注册登录后，通过拖拽创建 DAG 工作流，
      设置定时触发或 Webhook 触发，执行结果在仪表盘查看。"

名词 → 用户、工作流、DAG、触发器、执行结果、仪表盘
动词 → 注册登录、创建拖拽、设置触发、执行、查看

模块划分：
┌──────────────┬───────────────────────────────┐
│ auth         │ 用户、注册登录                  │
│ workflow     │ DAG、创建拖拽、工作流定义        │
│ trigger      │ 定时触发、Webhook 触发          │
│ execution    │ 执行、执行结果                  │
│ dashboard    │ 仪表盘、查看                    │
└──────────────┴───────────────────────────────┘
```

输出模块划分表并附确认问题，等待用户确认或调整。

### B3. 生成文档

| 文档 | 路径 | 模板 |
|------|------|------|
| Project Spec | `docs/spec/project-spec.md` | `assets/project-spec-template.md` |
| Main Flows | `docs/spec/main-flows.md` | 骨架：P0/P1 流程列表（5-10 条） |
| Module Spec | `docs/modules/<module>/spec.md` | `assets/module-spec-template.md` |

**Main Flows 示例骨架**：

| ID | 主流程 | 优先级 | 状态 |
|----|--------|--------|------|
| MF-001 | 用户注册→登录→进入系统 | P0 | ⏳ 待补充 |
| MF-002 | 创建工作流→触发执行→查看结果 | P0 | ⏳ 待补充 |

P0：核心端到端路径；P1：重要但非关键路径。宁少勿滥。

**Module Spec 内容**：模块职责（一句话）+ 功能列表（从 Epic 提取）+ 数据模型（占位）+ 对外接口（占位）。

### B4. 可选：拆分 Feat

如 Epic 包含明确功能列表，可拆分 feat 文档到 `docs/feat/feat-{编号}-{slug}.md`（模板参考 `issue-doc-gen/assets/feat-template.md`）。

### B5. full 模式：先 spec 后 code

full 模式下，spec 文档生成后自动询问是否继续生成代码骨架（跳过重复信息收集）。

---

## 输出总结

```
════════════════════════════════════════════════════════════════
✅ 项目初始化完成

📁 代码骨架（如选择）：
  my-project/  ← 项目目录结构 + 基础代码 + CI/CD

📄 Spec 文档（如选择）：
  docs/spec/project-spec.md        ← 项目全局规格
  docs/spec/main-flows.md          ← 主流程骨架
  docs/modules/<module>/spec.md    ← 各模块规格

📌 下一步：
  1. code-* 模式：开始开发 → /design-review-dev
  2. spec 模式：有 Epic 拆分 feat 后 → /feat-review-design
  3. full 模式：选择 feat 文档 → /feat-review-design
════════════════════════════════════════════════════════════════
```

---

## 目录结构（初始化后）

```
my-project/
├── ...                          ← 代码骨架（code-* / full）
├── docs/
│   ├── spec/
│   │   ├── project-spec.md      ← 项目全局规格
│   │   └── main-flows.md        ← 主流程骨架
│   ├── modules/
│   │   └── <module>/
│   │       ├── spec.md          ← 模块规格（活文档）
│   │       ├── design/          ← 设计文档（待生成）
│   │       └── fix/             ← 修复文档（待生成）
│   └── feat/                    ← 需求文档
```

---

## 资源

### 代码模板

| 目录 | 内容 |
|------|------|
| `templates/admin/` | Flask API 后端 + CI/CD |
| `templates/api/go/` | Go + Gin |
| `templates/api/python/` | Python + FastAPI |
| `templates/fullstack/` | Next.js 全栈 |
| `templates/microservice/` | Go 微服务 |
| `templates/common/logging/` | 各语言日志初始化代码 |

### 文档模板

| 文件 | 用途 |
|------|------|
| `assets/project-spec-template.md` | project-spec.md 模板 |
| `assets/module-spec-template.md` | module spec 模板 |

---

## 与其他 Skill 的关系

| 场景 | 使用的 Skill |
|------|-------------|
| 项目初始化（全模式） | **project-init** |
| 详细设计 | feat-review-design |
| 按设计开发 | design-review-dev |
| 前端/客户端 | ui-gen |
