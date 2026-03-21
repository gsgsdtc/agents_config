# {{PROJECT_NAME}} Admin

后台管理系统 - 基于 Ant Design Pro + Flask API（单镜像部署）

## 技术栈

### 前端
- React 18
- Ant Design 5
- Ant Design Pro Components
- UmiJS 4
- TypeScript

### 后端
- Python 3.11
- Flask 3.0
- Flask-RESTX (Swagger)
- SQLAlchemy
- SQLite / MySQL / PostgreSQL

## 快速开始

### 环境要求
- Node.js >= 18
- Python >= 3.11
- npm >= 9
- Docker (可选，用于生产部署)

### 安装依赖

```bash
make install
```

### 启动开发服务

```bash
# 同时启动前后端
make dev

# 仅启动前端 (http://localhost:8000)
make frontend

# 仅启动后端 (http://localhost:5000)
make backend
```

### 访问地址

**开发环境：**
- 前端: http://localhost:8000
- 后端 API: http://localhost:5000
- Swagger 文档: http://localhost:5000/swagger

**生产环境（单镜像）：**
- 应用: http://localhost:5000
- Swagger 文档: http://localhost:5000/swagger

## 构建与部署

### 构建 Docker 镜像

```bash
# 构建镜像（包含前后端）
make docker

# 本地运行容器
make docker-run

# 查看日志
make docker-logs

# 停止容器
make docker-stop
```

### 镜像说明

项目使用**多阶段构建**生成单一 Docker 镜像：
1. 第一阶段：使用 Node.js 构建前端静态文件
2. 第二阶段：使用 Python 打包后端 + 前端静态文件

最终镜像只包含 Python 运行时和打包好的应用。

## 数据库配置

### SQLite (默认)

默认使用 SQLite，数据文件保存在 `/app/data/app.db`

```bash
# Docker 运行时挂载数据目录
docker run -v $(pwd)/data:/app/data ...
```

### MySQL

设置环境变量：

```bash
DATABASE_URL=mysql+pymysql://user:password@host:3306/dbname
```

### PostgreSQL

设置环境变量：

```bash
DATABASE_URL=postgresql://user:password@host:5432/dbname
```

## 项目结构

```
{{PROJECT_NAME}}/
├── frontend/                 # 前端项目
│   ├── src/
│   │   ├── pages/           # 页面组件
│   │   ├── services/        # API 服务
│   │   ├── layouts/         # 布局组件
│   │   └── components/      # 公共组件
│   └── package.json
│
├── backend/                  # 后端项目
│   ├── app/
│   │   ├── api/             # API 路由
│   │   ├── models/          # 数据模型
│   │   └── config.py        # 配置文件
│   └── requirements.txt
│
├── Dockerfile                # 多阶段构建（单镜像）
├── Makefile                  # 开发命令
├── .gitlab-ci.yml            # CI/CD 配置
├── matrix.conf               # 部署配置
└── README.md
```

## CI/CD

项目使用 GitLab CI/CD：

| 分支 | 环境 | 触发方式 |
|------|------|----------|
| beta | 测试环境 | 手动 |
| main | 生产环境 | 手动 |

配置文件：
- `.gitlab-ci.yml` - CI/CD 流水线
- `matrix.conf` - 项目名称和命名空间

## API 文档

启动后端服务后，访问 `/swagger` 查看完整的 API 文档

### 主要接口

| 端点 | 方法 | 描述 |
|------|------|------|
| `/api/health/` | GET | 健康检查 |
| `/api/users/` | GET | 获取用户列表 |
| `/api/users/` | POST | 创建用户 |
| `/api/users/{id}` | GET | 获取用户详情 |
| `/api/users/{id}` | PUT | 更新用户 |
| `/api/users/{id}` | DELETE | 删除用户 |
| `/api/auth/login` | POST | 用户登录 |
| `/api/auth/logout` | POST | 用户登出 |
| `/api/auth/me` | GET | 获取当前用户 |

## 开发指南

### 添加新 API

1. 在 `backend/app/api/` 创建新的 namespace 文件
2. 在 `backend/app/__init__.py` 注册 namespace
3. 在 `frontend/src/services/api.ts` 添加对应的前端 API 调用

### 添加新页面

1. 在 `frontend/src/pages/` 创建新的页面目录
2. 在 `frontend/.umirc.ts` 添加路由配置
3. 在 `frontend/src/layouts/BasicLayout.tsx` 添加菜单项

## License

MIT
