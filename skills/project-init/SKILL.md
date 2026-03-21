---
name: project-init
description: |
  通用项目骨架生成，支持多种技术栈模式。

  触发条件：
  - "初始化项目" / "创建新项目" / "project-init"
  - "生成项目骨架" / "创建项目结构"
  - "新项目 setup" + 技术栈信息
  - 需要生成代码骨架时

  关键词识别：项目初始化、project init、骨架、scaffold、boilerplate
version: 0.3.0
---

# Project Init

## 目的

- 根据技术栈选择生成项目骨架
- 支持多种项目模式：admin、api、fullstack、microservice
- 生成基础代码、配置和 CI/CD 文件
- 吸收现有 admin-project-init 能力

## 支持模式

| 模式 | 说明 | 技术栈 |
|------|------|--------|
| **admin** | 后台 API 服务 | Flask API + Swagger |
| **api** | API 服务 | Go/Gin 或 Python/FastAPI |
| **fullstack** | 全栈应用 | 后端 + ui-gen 前端 |
| **microservice** | 微服务 | 多模块 Go/Node |

## 工作流

### 1) 交互式技术栈选择

```
🏗️ 项目类型选择

请选择项目类型：
  [1] admin - 后台 API 服务 (Flask + Swagger)
  [2] api - API 服务 (Go/Gin 或 Python/FastAPI)
  [3] fullstack - 全栈应用 (后端 + ui-gen)
  [4] microservice - 微服务架构

📝 项目信息
  项目名称 (英文，小写): my-project
  Git 仓库地址: https://github.com/user/my-project
  命名空间 (用于部署): my-namespace

🎨 技术栈选择

[admin 模式]
  后端: Flask + SQLAlchemy + Swagger
  数据库: [PostgreSQL/MySQL/SQLite]
  ⚠️ 前端项目请使用 ui-gen skill 初始化（支持 Web/iOS/Android 三端）

[api 模式]
  语言: [Go/Python/Node]
  框架: [Gin/FastAPI/Express]
  数据库: [PostgreSQL/MySQL/MongoDB]

[fullstack 模式]
  框架: [Next.js/Nuxt/SvelteKit]
  数据库: [PostgreSQL/Supabase/无]
```

### 2) 生成项目结构

根据选择的模式生成对应的项目结构：

#### admin 模式

```
my-project/
├── backend/                  # Flask API
│   ├── app/
│   │   ├── api/             # 路由
│   │   ├── models/          # 数据模型
│   │   ├── services/        # 业务逻辑
│   │   └── utils/
│   ├── migrations/          # 数据库迁移
│   ├── tests/
│   ├── app.py
│   ├── config.py
│   └── requirements.txt
├── docker-compose.yml
├── Dockerfile
├── Makefile
└── .gitlab-ci.yml / .github/workflows/
```

> **注意**：前端项目请使用 ui-gen skill 初始化（支持 Web/iOS/Android 三端）

#### api 模式 (Go)

```
my-project/
├── cmd/
│   └── server/
│       └── main.go
├── internal/
│   ├── config/
│   ├── handler/            # HTTP 处理器
│   ├── service/            # 业务逻辑
│   ├── repository/         # 数据访问
│   └── model/              # 数据模型
├── pkg/
│   ├── response/           # 统一响应
│   ├── errors/             # 错误处理
│   └── middleware/         # HTTP 中间件
├── api/
│   └── swagger/            # API 文档
├── configs/
│   └── config.yaml
├── scripts/
├── docker-compose.yml
├── Dockerfile
├── Makefile
└── go.mod
```

#### api 模式 (Python)

```
my-project/
├── app/
│   ├── api/
│   │   ├── deps.py         # 依赖注入
│   │   └── v1/
│   ├── core/
│   │   ├── config.py
│   │   └── security.py
│   ├── models/             # SQLAlchemy 模型
│   ├── schemas/            # Pydantic 模型
│   └── services/
├── alembic/                # 数据库迁移
├── tests/
├── Dockerfile
├── docker-compose.yml
├── requirements.txt
└── main.py
```

#### fullstack 模式 (Next.js)

```
my-project/
├── src/
│   ├── app/                # App Router
│   ├── components/
│   ├── lib/
│   ├── hooks/
│   └── types/
├── prisma/                 # 数据库 Schema
├── public/
├── tests/
├── Dockerfile
├── docker-compose.yml
├── next.config.js
├── tailwind.config.ts
└── package.json
```

### 3) 生成基础代码

**通用组件**：
- 统一的响应封装
- 错误处理中间件
- 日志配置（见下方）
- 数据库连接
- 认证中间件（JWT）
- 基础 CRUD 示例

**Admin 模式特有**：
- 用户管理 API
- JWT 认证与权限控制
- Swagger API 文档

**API 模式特有**：
- OpenAPI/Swagger 配置
- 健康检查接口
- 示例 CRUD 接口

#### 日志配置（必须生成）

所有模式均须在 `.env` 中生成日志配置项：

```env
# Logging
LOG_LEVEL=info
LOG_OUTPUT=console          # console | file | both
LOG_FILE_PATH=logs/app.log
LOG_MAX_SIZE=100            # 单个日志文件最大 MB
LOG_MAX_BACKUPS=5           # 保留的历史日志文件数
LOG_MAX_AGE=30              # 日志文件最大保留天数
```

**各技术栈 Logger 初始化示例**：

Go + Zap（`pkg/logger/logger.go`）：
```go
func InitLogger(cfg *config.LogConfig) {
    encoderCfg := zap.NewProductionEncoderConfig()
    encoderCfg.TimeKey = "timestamp"
    encoderCfg.EncodeTime = zapcore.ISO8601TimeEncoder

    var cores []zapcore.Core
    encoder := zapcore.NewJSONEncoder(encoderCfg)

    if cfg.Output == "console" || cfg.Output == "both" {
        cores = append(cores, zapcore.NewCore(encoder, zapcore.AddSync(os.Stdout), level))
    }
    if cfg.Output == "file" || cfg.Output == "both" {
        w := &lumberjack.Logger{
            Filename:   cfg.FilePath,
            MaxSize:    cfg.MaxSize,    // MB
            MaxBackups: cfg.MaxBackups,
            MaxAge:     cfg.MaxAge,
        }
        cores = append(cores, zapcore.NewCore(encoder, zapcore.AddSync(w), level))
    }
    Logger = zap.New(zapcore.NewTee(cores...))
}
```

Python + loguru（`app/core/logging.py`）：
```python
from loguru import logger
import sys

def init_logger(settings):
    logger.remove()
    fmt = "{time:YYYY-MM-DD HH:mm:ss} | {level} | {name} | {message}"
    if settings.LOG_OUTPUT in ("console", "both"):
        logger.add(sys.stdout, format=fmt, level=settings.LOG_LEVEL.upper())
    if settings.LOG_OUTPUT in ("file", "both"):
        logger.add(
            settings.LOG_FILE_PATH,
            format=fmt,
            level=settings.LOG_LEVEL.upper(),
            rotation=f"{settings.LOG_MAX_SIZE} MB",
            retention=f"{settings.LOG_MAX_AGE} days",
            compression="gz",
        )
```

Flask + logging（`app/utils/logger.py`）：
```python
import logging, sys
from logging.handlers import RotatingFileHandler

def init_logger(app):
    level = getattr(logging, app.config["LOG_LEVEL"].upper(), logging.INFO)
    fmt = logging.Formatter('{"time":"%(asctime)s","level":"%(levelname)s","module":"%(module)s","message":"%(message)s"}')
    handlers = []
    if app.config["LOG_OUTPUT"] in ("console", "both"):
        h = logging.StreamHandler(sys.stdout)
        h.setFormatter(fmt)
        handlers.append(h)
    if app.config["LOG_OUTPUT"] in ("file", "both"):
        h = RotatingFileHandler(
            app.config["LOG_FILE_PATH"],
            maxBytes=app.config["LOG_MAX_SIZE"] * 1024 * 1024,
            backupCount=app.config["LOG_MAX_BACKUPS"],
        )
        h.setFormatter(fmt)
        handlers.append(h)
    logging.basicConfig(level=level, handlers=handlers)
```

> **日志规范**（继承自 project-spec §6.3）：所有 POST/PUT/PATCH/DELETE 接口必须在入口打印请求参数、出口打印响应结果和耗时；GET 查询接口不强制。

### 4) 生成部署配置

**Docker 配置**：
```dockerfile
# Dockerfile (Go 示例)
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o server cmd/server/main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/server .
CMD ["./server"]
```

**docker-compose**：
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
  db:
    image: postgres:15
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
```

**CI/CD 配置**：
```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Go
        uses: actions/setup-go@v4
        with:
          go-version: '1.21'
      - run: make test
```

### 5) 生成 Makefile

```makefile
.PHONY: build test run docker clean

# 开发
run:
	go run cmd/server/main.go

dev:
	air

# 测试
test:
	go test -v ./...

test-coverage:
	go test -cover ./...

# 构建
build:
	go build -o bin/server cmd/server/main.go

# Docker
docker-build:
	docker build -t $(PROJECT):latest .

docker-run:
	docker-compose up -d

# 数据库
migrate-up:
	migrate -path migrations -database "$(DATABASE_URL)" up

migrate-down:
	migrate -path migrations -database "$(DATABASE_URL)" down

clean:
	rm -rf bin/
```

### 6) 输出总结

```
════════════════════════════════════════════════════════════════
✅ 项目初始化完成

📁 生成的项目结构：
  my-project/
  ├── backend/           # Flask API 后端
  ├── docker-compose.yml # 本地开发环境
  ├── Makefile          # 常用命令
  └── .github/workflows/ # CI/CD 配置

🚀 快速开始：
  cd my-project

  # 启动后端
  cd backend
  python -m venv venv
  source venv/bin/activate
  pip install -r requirements.txt
  flask run

  # 或使用 Docker
  docker-compose up -d

📌 下一步：
  1. 查看 README.md 了解项目结构
  2. 配置数据库连接
  3. 运行 spec-init 初始化文档体系
  4. 使用 ui-gen skill 初始化前端项目（支持 Web/iOS/Android 三端）
  5. 开始开发第一个功能

⚠️ 注意事项：
  - 默认使用 SQLite 便于本地开发，生产环境请切换为 PostgreSQL
  - 已配置 JWT 认证，密钥请在生产环境修改
  - 包含示例用户 admin/admin (开发环境)
  - 前端项目请使用 ui-gen skill 初始化（支持 Web/iOS/Android 三端）
════════════════════════════════════════════════════════════════
```

## 模式详情

### admin 模式

**后端** (Flask):
- Flask 2.x
- Flask-SQLAlchemy
- Flask-JWT-Extended
- Flask-Migrate
- Flask-RESTX (Swagger)
- Pytest 测试

> **注意**：前端项目请使用 ui-gen skill 初始化（支持 Web/iOS/Android 三端）

### api 模式

**Go 版本**:
- Gin 框架
- GORM
- Zap 日志
- Viper 配置
- JWT 认证
- Swagger 文档

**Python 版本**:
- FastAPI
- SQLAlchemy 2.0
- Pydantic v2
- Alembic 迁移
- Pytest + pytest-asyncio

### fullstack 模式

组合 admin 后端 + ui-gen 前端：
- 后端：Flask API（同 admin 模式）
- 前端：通过 ui-gen skill 初始化（Next.js + Tailwind + shadcn/ui）
- 数据库：PostgreSQL/MySQL/SQLite

## 与现有技能的关系

| 场景 | 使用的 Skill |
|------|-------------|
| 通用项目初始化 | project-init |
| 后台管理系统初始化 | project-init --mode=admin |
| 已有 spec 后的代码生成 | spec-init 后调用 project-init |
| 复杂业务系统 | spec-init → project-init → module-design |

**与 admin-project-init 的关系**：
- ✅ admin-project-init 已归并为 project-init 的 admin 模式
- project-init 统一入口，根据 `--mode=admin` 分发
- admin 模板文件位于 `templates/admin/`（backend/ + cicd/）
- admin-project-init 已标记为 deprecated，不再独立使用
- 前端模板已从 admin 模式移除，前端项目请使用 ui-gen skill 初始化

## 配置模板

模板文件位于 `templates/<mode>/` 目录：

```
templates/
├── admin/              # Flask API + Swagger (backend only)
├── api/
│   ├── go/            # Go + Gin
│   └── python/        # Python + FastAPI
├── fullstack/
│   └── nextjs/        # Next.js
└── microservice/
    └── go/            # Go 微服务
```

## 扩展机制

支持自定义模板：

```bash
# 使用自定义模板
claude /project-init --template=/path/to/custom-template
```

自定义模板需包含：
- `template.json` - 模板配置
- `files/` - 模板文件目录

## 资源

- Admin 模板: `templates/admin/`
  - `template.json` - 模板元数据配置
  - `backend/` - Flask API 后端模板（app, models, api, config, wsgi）
  - `cicd/` - CI/CD 部署模板（Dockerfile, Makefile, .gitlab-ci.yml, matrix.conf）
  - `_deprecated_frontend/` - 已废弃的 Ant Design Pro 前端模板（请使用 ui-gen skill）
- API 模板: `templates/api/`
- Fullstack 模板: `templates/fullstack/`
