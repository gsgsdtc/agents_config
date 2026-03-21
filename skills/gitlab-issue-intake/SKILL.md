---
name: gitlab-issue-intake
description: |
  从 GitLab 获取 issue 并自动创建开发分支。
  当用户要求"处理 issue/工单""获取或列出 GitLab issue""选择某个 issue"时使用。
  获取 issue 数据后自动委托给 issue-doc-gen 生成文档。
version: 1.0.0
---

# GitLab Issue Intake

## 重要说明

**此 skill 完全使用 GitLab REST API（curl），不依赖 GitLab MCP**

由于 GitLab MCP 不稳定，本 skill 通过 `curl` 直接调用 GitLab REST API 获取数据。

**依赖的 skill**：
- `gitlab-api`（提供基础 API 访问能力）
- `issue-doc-gen`（生成 feat/fix/集成测试文档）

## 目的

- 使用 GitLab REST API 从远程仓库获取 issue（不使用 MCP）
- 若缺少 issue 标题或 id/iid，则先列出现有 issue 供用户选择
- 选定 issue 后自动创建开发分支
- 委托 `issue-doc-gen` 生成对应文档和集成测试用例

## 环境配置

### 必需的环境变量

在使用此 skill 前，必须设置 GitLab token 环境变量：

```bash
# 方式一：临时设置（当前会话有效）
export GITLAB_TOKEN="your-gitlab-personal-access-token"

# 方式二：永久设置（添加到 ~/.bashrc 或 ~/.zshrc）
echo 'export GITLAB_TOKEN="your-gitlab-personal-access-token"' >> ~/.bashrc
source ~/.bashrc
```

**获取 GitLab Token**：
1. 访问 GitLab → Settings → Access Tokens
2. 创建 Personal Access Token，勾选 `read_api` 权限
3. 复制生成的 token 并设置到环境变量

## 工作流

### 1) 检查环境配置

执行以下命令验证配置：

```bash
# 检查 token 是否设置
if [ -z "$GITLAB_TOKEN" ]; then
  echo "❌ GITLAB_TOKEN 未设置"
  echo ""
  echo "请按以下步骤配置："
  echo "1. 访问 GitLab → Settings → Access Tokens"
  echo "2. 创建 Personal Access Token（勾选 api 或 read_api 权限）"
  echo "3. 执行: export GITLAB_TOKEN=\"your-token\""
  echo ""
  echo "永久设置："
  echo "  echo 'export GITLAB_TOKEN=\"your-token\"' >> ~/.bashrc && source ~/.bashrc"
  # 停止执行，等待用户配置
else
  echo "✅ GITLAB_TOKEN 已设置"
fi
```

如果 token 未设置，**必须停止并等待用户配置后再继续**。

### 2) 获取项目信息和项目 ID

从 git remote 提取 GitLab 项目路径，并获取项目 ID：

```bash
# 检查是否在 git 仓库中
REMOTE_URL=$(git remote get-url origin 2>/dev/null)
if [ -z "$REMOTE_URL" ]; then
  echo "❌ 当前目录不是 git 仓库或没有 origin remote"
  echo "请切换到正确的项目目录"
  exit 1
fi

# 根据 URL 格式解析主机和项目路径
if [[ "$REMOTE_URL" =~ ^git@ ]]; then
  # SSH 格式: git@gitlab.meitu.com:ai-open-platform/modules/coze-studio.git
  GITLAB_HOST=$(echo "$REMOTE_URL" | sed 's|^git@\([^:]*\):.*|\1|')
  PROJECT_PATH_RAW=$(echo "$REMOTE_URL" | sed 's|^git@[^:]*:||' | sed 's|\.git$||')
else
  # HTTPS 格式: https://gitlab.meitu.com/ai-open-platform/modules/coze-studio.git
  GITLAB_HOST=$(echo "$REMOTE_URL" | sed 's|^https*://\([^/]*\)/.*|\1|')
  PROJECT_PATH_RAW=$(echo "$REMOTE_URL" | sed 's|^https*://[^/]*/||' | sed 's|\.git$||')
fi

# URL 编码路径（/ → %2F）
PROJECT_PATH=$(echo "$PROJECT_PATH_RAW" | sed 's|/|%2F|g')

# 获取项目 ID（数字）
PROJECT_ID=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}" | jq -r '.id')

# 验证连接
if [ "$PROJECT_ID" = "null" ] || [ -z "$PROJECT_ID" ]; then
  echo "❌ 无法获取项目 ID，请检查："
  echo "   - GITLAB_TOKEN 是否有效"
  echo "   - 是否有权限访问此项目"
  exit 1
fi

echo "================================"
echo "GitLab 项目信息"
echo "================================"
echo "Host:       $GITLAB_HOST"
echo "Project:    $PROJECT_PATH_RAW"
echo "Project ID: $PROJECT_ID"
echo "================================"
```

**输出变量**（供后续步骤使用）：
- `GITLAB_HOST`：GitLab 主机地址
- `PROJECT_PATH`：URL 编码的项目路径
- `PROJECT_ID`：项目数字 ID

### 3) 列出 Issue（使用 GitLab API）

当需要列出 issue 时，使用以下 API：

```bash
# 列出最近的 issue（默认按更新时间排序）
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/issues?state=opened&per_page=20&order_by=updated_at" \
  | jq '.[] | {iid, title, labels, state, updated_at, web_url}'
```

返回字段说明：
- `iid`：项目内的 issue 编号
- `title`：issue 标题
- `labels`：标签列表
- `state`：状态（opened/closed）
- `updated_at`：更新时间
- `web_url`：issue 链接

### 4) 获取单个 Issue 详情

当用户指定 issue 编号后：

```bash
# 获取单个 issue 详情
ISSUE_IID=<用户指定的编号>
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://${GITLAB_HOST}/api/v4/projects/${PROJECT_PATH}/issues/${ISSUE_IID}" \
  | jq '{iid, title, description, labels, state, author, assignees, created_at, updated_at, web_url}'
```

### 5) 创建分支（自动）

在确认 issue 后自动创建分支：

```bash
# 生成分支名（将标题转为 slug）
ISSUE_IID=<编号>
SLUG=$(echo "<issue标题>" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-' | sed 's/^-//;s/-$//' | cut -c1-50)

# 根据类型创建分支
# bug: fix/<iid>-<slug>
# feat: feat/<iid>-<slug>
# 未确认: issue-<iid>-<slug>

git checkout -b "feat/${ISSUE_IID}-${SLUG}"  # 或 fix/...
```

**前置检查**：
- 若当前目录不是 git 仓库，提示用户切换目录
- 若有未提交改动，提示用户先处理
- 若分支已存在，询问是否切换到该分支

### 6) 委托文档生成

获取 issue 数据并创建分支后，**自动调用 `issue-doc-gen` skill** 生成文档：

将以下信息传递给 `issue-doc-gen`：
- `iid`：issue 编号
- `title`：issue 标题
- `description`：issue 描述
- `labels`：标签列表
- `web_url`：issue 链接
- `state`：状态
- `project`：项目路径

`issue-doc-gen` 将负责：
- 判断 issue 类型（bug/feat）
- 生成对应文档（fix/feat）
- 生成集成测试用例
- 展示对齐问题清单
- 等待用户确认

### 7) 异常处理

**Token 未设置**：
```
❌ GITLAB_TOKEN 环境变量未设置

请按以下步骤配置：
1. 访问 GitLab → Settings → Access Tokens
2. 创建 Personal Access Token（勾选 read_api 权限）
3. 设置环境变量：export GITLAB_TOKEN="your-token"
```

**API 请求失败**：
- 401 Unauthorized：Token 无效或已过期
- 404 Not Found：项目或 issue 不存在
- 403 Forbidden：无权限访问

当 API 不可用时，请求用户提供 issue 链接或关键信息，然后直接调用 `issue-doc-gen` 手动填写文档。

## GitLab API 参考

| 操作 | API 端点 | 方法 |
|------|----------|------|
| 列出 issues | `/api/v4/projects/:id/issues` | GET |
| 获取单个 issue | `/api/v4/projects/:id/issues/:issue_iid` | GET |
| 列出 issue 评论 | `/api/v4/projects/:id/issues/:issue_iid/notes` | GET |

**常用查询参数**：
- `state`：opened, closed, all
- `labels`：按标签过滤（逗号分隔）
- `search`：搜索标题和描述
- `order_by`：排序字段（created_at, updated_at）
- `per_page`：每页数量（默认 20，最大 100）
