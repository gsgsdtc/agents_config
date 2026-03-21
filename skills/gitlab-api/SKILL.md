---
name: gitlab-api
description: GitLab REST API 基础访问工具。当需要访问 GitLab 数据（项目、issue、MR、分支等）时使用此 skill，完全通过 curl 调用 REST API，不依赖 GitLab MCP。
version: 1.0.0
---

# GitLab API 基础工具

## 目的

提供稳定可靠的 GitLab REST API 访问能力，不依赖 GitLab MCP。

**重要**：此 skill 完全使用 `curl` 调用 GitLab REST API，避免 MCP 不稳定问题。

## 环境配置

### 必需的环境变量

| 变量名 | 说明 | 必需 |
|--------|------|------|
| `GITLAB_TOKEN` | GitLab Personal Access Token | 是 |
| `GITLAB_HOST` | GitLab 主机地址（可选，从 git remote 自动获取） | 否 |

### 检查和设置环境变量

```bash
# 检查 GITLAB_TOKEN 是否设置
if [ -z "$GITLAB_TOKEN" ]; then
  echo "❌ GITLAB_TOKEN 未设置"
  echo ""
  echo "请按以下步骤配置："
  echo "1. 访问 GitLab → Settings → Access Tokens"
  echo "2. 创建 Personal Access Token（勾选 api 或 read_api 权限）"
  echo "3. 执行: export GITLAB_TOKEN=\"your-token\""
  echo ""
  echo "永久设置（添加到 ~/.bashrc）："
  echo "  echo 'export GITLAB_TOKEN=\"your-token\"' >> ~/.bashrc && source ~/.bashrc"
else
  echo "✅ GITLAB_TOKEN 已设置"
fi
```

### 获取 GitLab Token

1. 访问 GitLab → **Settings** → **Access Tokens**
2. 创建 Personal Access Token：
   - 名称：`claude-code-api`
   - 权限：勾选 `api`（完整访问）或 `read_api`（只读访问）
   - 过期时间：按需设置
3. 复制 token 并设置环境变量

## 核心函数

### 1) 获取项目信息

```bash
# 从 git remote 获取 GitLab 主机和项目路径
gitlab_get_project_info() {
  local REMOTE_URL=$(git remote get-url origin 2>/dev/null)

  if [ -z "$REMOTE_URL" ]; then
    echo "❌ 当前目录不是 git 仓库或没有 origin remote"
    return 1
  fi

  local HOST=""
  local PATH_RAW=""

  # 根据 URL 格式解析
  if [[ "$REMOTE_URL" =~ ^git@ ]]; then
    # SSH 格式: git@gitlab.meitu.com:ai-open-platform/modules/coze-studio.git
    HOST=$(echo "$REMOTE_URL" | sed 's|^git@\([^:]*\):.*|\1|')
    PATH_RAW=$(echo "$REMOTE_URL" | sed 's|^git@[^:]*:||' | sed 's|\.git$||')
  else
    # HTTPS 格式: https://gitlab.meitu.com/ai-open-platform/modules/coze-studio.git
    HOST=$(echo "$REMOTE_URL" | sed 's|^https*://\([^/]*\)/.*|\1|')
    PATH_RAW=$(echo "$REMOTE_URL" | sed 's|^https*://[^/]*/||' | sed 's|\.git$||')
  fi

  # URL 编码路径（/ → %2F）
  local PATH_ENCODED=$(echo "$PATH_RAW" | sed 's|/|%2F|g')

  echo "GITLAB_HOST=$HOST"
  echo "PROJECT_PATH=$PATH_ENCODED"
  echo "PROJECT_PATH_RAW=$PATH_RAW"
}

# 使用示例
eval $(gitlab_get_project_info)
echo "Host: $GITLAB_HOST"
echo "Project: $PROJECT_PATH_RAW"
```

### 2) 获取项目 ID

```bash
# 通过项目路径获取项目 ID（数字）
gitlab_get_project_id() {
  local HOST="${1:-$GITLAB_HOST}"
  local PROJECT="${2:-$PROJECT_PATH}"

  curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "https://${HOST}/api/v4/projects/${PROJECT}" \
    | jq -r '.id'
}

# 使用示例
PROJECT_ID=$(gitlab_get_project_id)
echo "Project ID: $PROJECT_ID"
```

### 3) 验证 API 连接

```bash
# 验证 token 和项目访问权限
gitlab_verify_connection() {
  local HOST="${1:-$GITLAB_HOST}"
  local PROJECT="${2:-$PROJECT_PATH}"

  local RESPONSE=$(curl -s -w "\n%{http_code}" --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "https://${HOST}/api/v4/projects/${PROJECT}")

  local HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
  local BODY=$(echo "$RESPONSE" | sed '$d')

  case "$HTTP_CODE" in
    200)
      echo "✅ 连接成功"
      echo "$BODY" | jq '{id, name, path_with_namespace, web_url}'
      ;;
    401)
      echo "❌ 401 Unauthorized - Token 无效或已过期"
      ;;
    403)
      echo "❌ 403 Forbidden - 无权限访问此项目"
      ;;
    404)
      echo "❌ 404 Not Found - 项目不存在: $PROJECT"
      ;;
    *)
      echo "❌ HTTP $HTTP_CODE - 未知错误"
      echo "$BODY"
      ;;
  esac
}
```

## API 操作

### Issues

```bash
# 列出 issues
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/issues?state=opened&per_page=20&order_by=updated_at" \
  | jq '.[] | {iid, title, labels, state, updated_at, web_url}'

# 获取单个 issue
ISSUE_IID=123
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/issues/${ISSUE_IID}" \
  | jq '{iid, title, description, labels, state, author, assignees, created_at, updated_at, web_url}'

# 获取 issue 评论
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/issues/${ISSUE_IID}/notes" \
  | jq '.[] | {id, body, author: .author.username, created_at}'

# 搜索 issues
SEARCH_TERM="bug"
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/issues?search=${SEARCH_TERM}&state=opened" \
  | jq '.[] | {iid, title, labels}'
```

### Merge Requests

```bash
# 列出 MRs
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/merge_requests?state=opened&per_page=20" \
  | jq '.[] | {iid, title, source_branch, target_branch, author: .author.username, web_url}'

# 获取单个 MR
MR_IID=456
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/merge_requests/${MR_IID}" \
  | jq '{iid, title, description, source_branch, target_branch, state, author, reviewers, web_url}'

# 获取 MR 变更
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/merge_requests/${MR_IID}/changes" \
  | jq '{title, changes: [.changes[] | {old_path, new_path, diff: .diff[:200]}]}'
```

### Branches

```bash
# 列出分支
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/repository/branches?per_page=20" \
  | jq '.[] | {name, merged, protected, commit: .commit.short_id}'

# 获取单个分支
BRANCH_NAME="main"
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/repository/branches/${BRANCH_NAME}" \
  | jq '{name, merged, protected, commit: .commit}'
```

### Pipelines

```bash
# 列出 pipelines
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/pipelines?per_page=10" \
  | jq '.[] | {id, status, ref, created_at, web_url}'

# 获取 pipeline 详情
PIPELINE_ID=789
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/pipelines/${PIPELINE_ID}" \
  | jq '{id, status, ref, duration, created_at, finished_at, web_url}'

# 获取 pipeline jobs
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/pipelines/${PIPELINE_ID}/jobs" \
  | jq '.[] | {id, name, stage, status, duration, web_url}'
```

### Files

```bash
# 获取文件内容
FILE_PATH="README.md"
BRANCH="main"
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/repository/files/${FILE_PATH}/raw?ref=${BRANCH}"

# 列出目录
DIRECTORY_PATH="src"
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/repository/tree?path=${DIRECTORY_PATH}&ref=${BRANCH}" \
  | jq '.[] | {name, type, path}'
```

## 快速初始化脚本

```bash
#!/bin/bash
# GitLab API 初始化脚本

# 检查 token
if [ -z "$GITLAB_TOKEN" ]; then
  echo "❌ 请先设置 GITLAB_TOKEN 环境变量"
  exit 1
fi

# 获取项目信息
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
if [ -z "$REMOTE_URL" ]; then
  echo "❌ 请在 git 仓库目录下运行"
  exit 1
fi

# 解析 host 和 path
if [[ "$REMOTE_URL" =~ ^git@ ]]; then
  # SSH 格式: git@gitlab.meitu.com:ai-open-platform/modules/coze-studio.git
  GITLAB_HOST=$(echo "$REMOTE_URL" | sed 's|^git@\([^:]*\):.*|\1|')
  PROJECT_PATH_RAW=$(echo "$REMOTE_URL" | sed 's|^git@[^:]*:||' | sed 's|\.git$||')
else
  # HTTPS 格式: https://gitlab.meitu.com/ai-open-platform/modules/coze-studio.git
  GITLAB_HOST=$(echo "$REMOTE_URL" | sed 's|^https*://\([^/]*\)/.*|\1|')
  PROJECT_PATH_RAW=$(echo "$REMOTE_URL" | sed 's|^https*://[^/]*/||' | sed 's|\.git$||')
fi

PROJECT_PATH=$(echo "$PROJECT_PATH_RAW" | sed 's|/|%2F|g')

# 获取项目 ID
PROJECT_ID=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}" | jq -r '.id')

# 输出结果
echo "================================"
echo "GitLab API 初始化完成"
echo "================================"
echo "Host:       $GITLAB_HOST"
echo "Project:    $PROJECT_PATH_RAW"
echo "Project ID: $PROJECT_ID"
echo "================================"

# 导出变量供后续使用
export GITLAB_HOST PROJECT_PATH PROJECT_PATH_RAW PROJECT_ID
```

## API 参考

| 资源 | 端点 | 方法 |
|------|------|------|
| 项目信息 | `/api/v4/projects/:id` | GET |
| Issues 列表 | `/api/v4/projects/:id/issues` | GET |
| Issue 详情 | `/api/v4/projects/:id/issues/:iid` | GET |
| Issue 评论 | `/api/v4/projects/:id/issues/:iid/notes` | GET |
| MRs 列表 | `/api/v4/projects/:id/merge_requests` | GET |
| MR 详情 | `/api/v4/projects/:id/merge_requests/:iid` | GET |
| MR 变更 | `/api/v4/projects/:id/merge_requests/:iid/changes` | GET |
| 分支列表 | `/api/v4/projects/:id/repository/branches` | GET |
| Pipeline 列表 | `/api/v4/projects/:id/pipelines` | GET |
| 文件内容 | `/api/v4/projects/:id/repository/files/:path/raw` | GET |

**常用查询参数**：
- `state`: opened, closed, merged, all
- `labels`: 按标签过滤（逗号分隔）
- `search`: 搜索标题和描述
- `order_by`: 排序字段（created_at, updated_at）
- `sort`: asc, desc
- `per_page`: 每页数量（默认 20，最大 100）
- `page`: 页码

## 错误处理

| HTTP 状态码 | 含义 | 解决方案 |
|-------------|------|----------|
| 200 | 成功 | - |
| 401 | 未授权 | 检查 GITLAB_TOKEN 是否有效 |
| 403 | 禁止访问 | 检查 token 权限或项目访问权限 |
| 404 | 未找到 | 检查项目路径或资源 ID |
| 429 | 请求过多 | 稍后重试，注意 API 限流 |
