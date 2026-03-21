---
name: spec-extract
description: |
  从现有代码逆向提取 module-spec，用于旧项目迁移到 spec-driven 体系。

  触发条件：
  - "提取 spec" / "spec-extract" / "逆向生成 spec"
  - "旧项目迁移" / "生成模块文档"
  - "从代码提取文档" / "逆向文档"
  - 已有项目希望采用 spec-driven 体系

  关键词识别：spec-extract、逆向、提取、迁移、旧项目、生成文档
version: 0.2.0
---

# Spec Extract

## 目的

- 从现有代码逆向提取 module-spec
- 支持旧项目迁移到 spec-driven 文档体系
- 自动生成 spec.md 草稿，用户 review 后确认

## 输入

| 输入项 | 说明 | 来源 |
|--------|------|------|
| 代码仓库 | 目标项目代码 | 当前目录或指定路径 |
| 模块划分 | 代码模块结构 | 目录结构或用户输入 |
| 编程语言 | Go/Python/Java/Node | 文件扩展名自动识别 |

## 工作流

### 1) 扫描项目结构

**识别项目类型和模块结构**：

```bash
# 典型 Go 项目结构
.
├── internal/
│   ├── auth/          ← 模块
│   ├── workflow/      ← 模块
│   └── execution/     ← 模块
├── pkg/
│   └── utils/
└── api/
    └── routes/

# 典型 Python 项目结构
.
├── app/
│   ├── models/
│   ├── routes/
│   └── services/
├── auth/              ← 模块
├── workflow/          ← 模块
└── utils/
```

**输出模块列表**：
```
📋 检测到的模块：

| 模块 | 路径 | 文件数 | 语言 |
|------|------|--------|------|
| auth | internal/auth | 12 | Go |
| workflow | internal/workflow | 18 | Go |
| execution | internal/execution | 15 | Go |
```

### 2) 使用 Serena 扫描代码

**对每个模块执行符号扫描**：

```yaml
# 使用 Serena MCP 工具
serena:
  - list_dir: {relative_path: "internal/auth", recursive: true}
  - get_symbols_overview: {relative_path: "internal/auth/handler.go"}
  - find_symbol: {name_path_pattern: "AuthHandler", include_body: true}
```

**扫描目标**：

整体扫描模块目录内的所有代码符号，不按技术层分类：

| 扫描内容 | 说明 |
|----------|------|
| 所有公开函数/方法 | 模块对外暴露的能力 |
| 所有结构体/类定义 | 模块的数据模型 |
| 常量/枚举定义 | 错误码、状态等 |
| 导入关系 | 模块间依赖 |

> 注意：不按 handler/service/repo 分层提取，而是将整个模块目录视为一个业务单元整体分析。

### 3) 创建 Subagent 分析代码

**为每个模块创建 subagent** 并行分析：

```yaml
# Subagent 配置
name: "code-analyzer-agent"
input:
  module_name: "auth"
  module_path: "internal/auth"
  language: "go"
  symbols: [LoginHandler, RegisterHandler, OAuthCallback, User, OAuthBinding, AuthService, TokenService, ErrInvalidToken, ...]
  file_contents: "{key_file_contents}"
output:
  spec_draft: "{spec_content}"  # 按 module-spec 模板格式
```

> symbols 是模块内所有公开符号的扁平列表，不按技术层分类。由 subagent 在分析阶段自行判断每个符号属于接口、模型还是业务逻辑。

**Subagent Prompt 模板**：`prompts/code-analyzer.md`

### 4) 生成 Spec 草稿

**按模块生成 spec.md**：

```markdown
# Module Spec: auth

> 所属项目：{project_name}
> 更新日期：2026-02-12
> 最近同步：2026-02-12（从代码提取）
> ⚠️ 状态：草稿 - 需人工 review

## 1. 模块职责

### 边界
- **负责**：认证鉴权、用户管理、OAuth 集成
- **不负责**：权限管理（rbac 模块负责）

## 2. 功能列表

| 功能 | 说明 | 状态 | 关联 |
|------|------|------|------|
| 用户注册 | 用户名密码注册 | ✅ 已实现 | - |
| 用户登录 | 用户名密码登录 | ✅ 已实现 | - |
| OAuth 登录 | 第三方登录 | ✅ 已实现 | - |

## 3. 数据模型

### 3.1 实体

| 实体 | 说明 | 关键字段 |
|------|------|---------|
| User | 用户 | id, username, password_hash, email |
| OAuthBinding | OAuth 绑定 | id, user_id, provider, provider_uid |

### 3.2 实体关系

```
User 1──N OAuthBinding
```

## 4. 对外接口

### 4.1 API 接口

| 方法 | 路径 | 说明 | 输入概要 | 输出概要 |
|------|------|------|---------|---------|
| POST | /api/auth/register | 用户注册 | username, password, email | user_id, token |
| POST | /api/auth/login | 用户登录 | username, password | token |
| POST | /api/auth/oauth/callback | OAuth 回调 | provider, code | token |

### 4.2 内部接口

| 函数/方法 | 说明 | 调用方 |
|-----------|------|--------|
| AuthService.Login(username, password) | 登录核心逻辑 | LoginHandler |
| TokenService.Generate(userID) | 生成 JWT | AuthService |

## 5. 核心逻辑

### 5.1 业务规则
- 用户名全局唯一
- 密码需满足复杂度要求
- 同一 provider 只能绑定一次

### 5.2 关键流程

**登录流程**：
1. 验证用户名密码
2. 生成 JWT Token
3. 记录登录日志

## 6. 依赖关系

| 方向 | 类型 | 模块/服务 | 说明 |
|------|------|-----------|------|
| 依赖 → | 数据库 | PostgreSQL | 用户数据存储 |
| 依赖 → | 缓存 | Redis | Session 存储 |
| ← 被依赖 | HTTP | api-gateway | Token 校验 |

## 7. 变更记录

| 日期 | feat/fix | 变更内容 |
|------|----------|---------|
| 2026-02-12 | - | 从代码逆向提取初始版本 |
```

### 5) 用户 Review

**输出提示**：
```
════════════════════════════════════════════════════════════════
✅ Spec 提取完成

📄 生成的草稿文档：
  📄 docs/modules/auth/spec.md      (提取自 internal/auth)
  📄 docs/modules/workflow/spec.md  (提取自 internal/workflow)
  📄 docs/modules/execution/spec.md (提取自 internal/execution)

⚠️ 重要提示：
  这些文档是自动提取的草稿，需要人工 review 和修正：

  1. 检查「模块职责」描述是否准确
  2. 确认「边界」划分是否合理
  3. 补充缺失的业务规则说明
  4. 验证接口参数和返回值的完整性
  5. 调整依赖关系表

📌 下一步：
  1. 逐一 review 各模块 spec.md
  2. 修正不准确的内容
  3. 移除 ⚠️ 草稿状态标记
  4. 运行 spec-init 初始化完整的文档体系
════════════════════════════════════════════════════════════════
```

## 代码提取规则

### 核心原则：按业务模块整体提取

每个业务模块（如 `auth/`、`workflow/`、`order/`）作为一个完整单元分析，**不按技术层（handler/service/repo）拆分**。

**提取流程**：
1. 扫描模块目录下的**所有代码文件**
2. 提取所有公开符号（函数、类型、常量）
3. 由 subagent 根据符号的语义**自行判断**其归属：
   - 接收 HTTP 请求的 → §4.1 对外接口
   - 被其他模块调用的 → §4.2 内部接口
   - 数据结构定义 → §3 数据模型
   - 包含业务判断逻辑的 → §5 核心逻辑
   - 错误码/状态常量 → §5.5 错误码 / §6 状态机

### 语言特定的符号识别提示

以下仅作为 subagent 判断符号归属的**参考线索**，不作为硬性分层规则：

| 语言 | 线索 | 可能归属 |
|------|------|----------|
| Go | `func XXX(c *gin.Context)` | 对外接口 |
| Go | `type XXX struct` | 数据模型 |
| Python | `@app.route` / `class XXXView` | 对外接口 |
| Python | `class XXX(models.Model)` | 数据模型 |
| Java | `@RestController` / `@RequestMapping` | 对外接口 |
| Java | `@Entity` | 数据模型 |
| Node.js | `router.get/post/put/delete` | 对外接口 |
| Node.js | `mongoose.Schema` / `Sequelize.define` | 数据模型 |

## Subagent 说明

### code-analyzer-agent

**职责**：分析单个模块的代码，生成 spec 草稿

**输入**：
- module_name: 模块名
- module_path: 代码路径
- language: 编程语言
- symbols: 模块内所有公开符号（扁平列表，不按层分类）
- file_contents: 关键文件内容

**输出**：
- 按 module-spec 模板格式生成的 spec 内容

**Prompt 模板**：`prompts/code-analyzer.md`

## 辅助脚本

`scripts/project-scanner.sh` - 项目结构扫描（识别语言、框架和业务模块边界）

## 使用场景

### 场景 1：旧项目迁移到 spec-driven

```
用户：把现有项目迁移到 spec-driven 体系
Claude：
  1. 扫描项目结构
  2. 识别模块划分
  3. 从代码提取 spec
  4. 生成草稿文档
  5. 提示用户 review
```

### 场景 2：补充缺失的模块文档

```
用户：给 auth 模块生成 spec 文档
Claude：
  1. 扫描 internal/auth 目录
  2. 提取接口和模型
  3. 生成 spec.md
```

### 场景 3：与 spec-init 配合

```
用户：现有项目想采用 spec-driven
Claude spec-extract：
  1. 从代码提取模块和 spec 草稿

用户 review 并修正

Claude spec-init：
  1. 基于现有模块初始化完整文档体系
  2. 生成 project-spec.md
  3. 组织 feat/fix 目录
```

## 限制与注意事项

1. **代码注释依赖**：提取质量依赖代码结构和命名
2. **无法提取业务规则**：需要人工补充业务逻辑说明
3. **复杂逻辑简化**：复杂的内部逻辑可能需要人工细化
4. **缺少历史信息**：无法自动提取变更历史

## 资源

- Subagent Prompt: `prompts/code-analyzer.md`
- 辅助脚本: `scripts/project-scanner.sh`
- Module Spec 模板: `../spec-init/assets/module-spec-template.md`
