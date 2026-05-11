# Project Spec: {项目名称}

> 版本：v0.1.0
> 更新日期：{date}

## 1. 项目概述

### 1.1 目标
{一句话描述项目解决什么问题}

### 1.2 非目标
- {明确不做什么}
- {明确不做什么}

## 2. 技术栈

| 层级 | 选型 | 版本 |
|------|------|------|
| 前端 | {React / Vue / ...} | |
| 后端 | {Go + Gin / Python + Flask / ...} | |
| 数据库 | {PostgreSQL / MySQL / ...} | |
| 缓存 | {Redis / 无} | |
| 消息队列 | {RabbitMQ / Kafka / 无} | |
| CI/CD | {GitLab CI / GitHub Actions} | |

## 3. 系统架构

### 3.1 架构图

{文字描述或 mermaid 图}

### 3.2 部署架构

{单机 / Docker Compose / K8s，环境划分}

## 4. 模块划分

| 模块 | 职责 | 对应目录 |
|------|------|---------|
| {module} | {职责} | internal/{module} |
| {module} | {职责} | internal/{module} |

### 4.1 模块依赖关系

{文字或 mermaid 描述模块间调用关系}

## 5. 全局约束

### 5.1 编码规范
- {语言规范、lint 规则、commit 规范}

### 5.2 性能要求
- {API 响应时间、并发量、吞吐量}

### 5.3 安全要求
- {认证方式、数据加密、审计日志}

### 5.4 兼容性
- {浏览器支持、API 版本策略、数据迁移策略}

## 6. 项目约定

### 6.1 API 规范
- 路径风格：`/api/v1/{resource}`，复数名词，kebab-case
- 响应格式：`{"code": 0, "data": {}, "message": ""}`
- 分页格式：`{"list": [], "total": 100, "page": 1, "page_size": 20}`
- 错误码：模块前缀 + 序号，如 `AUTH_001`、`WF_001`

### 6.2 数据库约定
- 表名：snake_case 复数（`users`、`workflow_runs`）
- 主键：`id` (bigint auto increment)
- 时间字段：`created_at`、`updated_at`、`deleted_at`（软删除）
- Migration：`{timestamp}_{description}.sql`

### 6.3 日志规范
- 结构化日志，JSON 格式
- 必含字段：`timestamp`、`level`、`module`、`trace_id`
- ERROR 级别必须包含 `error` 和 `stack` 字段
- **外部接口日志强制规则**：所有增删改接口（POST/PUT/PATCH/DELETE）必须在入口和出口各打一条 INFO 日志，入口日志含请求参数，出口日志含响应结果和耗时；GET 查询接口不强制（可酌情记录）
- 日志输出通过 `.env` 配置（`LOG_OUTPUT=console|file|both`、`LOG_FILE_PATH`、`LOG_MAX_SIZE`）

### 6.4 测试约定
- 单元测试与源码同目录（`xxx_test.go`）
- Mock 库：{gomock / testify / ...}
- 测试数据库：{SQLite in-memory / testcontainers / ...}

## 7. 公共模块

| 模块 | 路径 | 用途 | 关键接口 |
|------|------|------|---------|
| response | pkg/response | 统一响应封装 | `OK(data)`, `Error(code, msg)` |
| errors | pkg/errors | 错误包装 | `Wrap(err, msg)`, `Is(err, target)` |
| middleware | pkg/middleware | HTTP 中间件 | `Auth()`, `CORS()`, `Logger()` |
| pagination | pkg/pagination | 分页解析 | `Parse(c) → (page, size, offset)` |
