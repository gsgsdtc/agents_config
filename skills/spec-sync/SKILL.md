---
name: spec-sync
description: |
  开发完成后回写 module-spec，保持 spec 与代码同步（闭环能力）。

  触发条件：
  - "同步 spec" / "spec-sync" / "回写 spec"
  - "更新模块文档" / "同步模块规格"
  - 开发完成后更新 spec.md
  - MR 合并后同步文档

  关键词识别：spec-sync、回写、同步、更新 spec、闭环
version: 0.2.0
---

# Spec Sync

## 目的

- 开发完成后自动/半自动更新 module-spec.md
- 保持 spec 作为「活文档」与代码同步
- 支持从 MR diff、代码变更提取 spec 更新

## 输入

| 输入项 | 说明 | 来源 |
|--------|------|------|
| MR diff / git diff | 代码变更 | `git diff` / GitLab API |
| 原 module-spec | 现有模块规格 | `docs/modules/{module}/spec.md` |
| 设计文档 | 开发依据的设计 | `docs/modules/{module}/design/*.md` |

## 工作流

### 1) 获取代码变更

**方式 A：本地 git diff**
```bash
# 获取当前分支与 main 的差异
git diff main...HEAD
```

**方式 B：GitLab MR diff**
```bash
# 通过 GitLab API 获取 MR diff
curl -H "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.com/api/v4/projects/$PROJECT_ID/merge_requests/$MR_ID/changes"
```

### 2) 分析变更范围

**解析 diff，识别变更模块**：

```python
# 伪代码
def analyze_diff(diff_content):
    changes = {
        'auth': {'apis': [], 'models': [], 'logic': []},
        'workflow': {'apis': [], 'models': [], 'logic': []}
    }

    for file in diff_files:
        module = extract_module_from_path(file.path)

        if is_api_file(file):
            changes[module]['apis'].extend(extract_api_changes(file))
        elif is_model_file(file):
            changes[module]['models'].extend(extract_model_changes(file))
        elif is_logic_file(file):
            changes[module]['logic'].append(file.changes_summary)

    return changes
```

**输出变更摘要**：
```
📋 变更分析结果：

| 模块 | API 变更 | 模型变更 | 逻辑变更 |
|------|---------|---------|---------|
| auth | +2 API | +1 实体 | OAuth 登录流程 |
| user | 0 | +1 字段 | 无 |
```

### 3) 生成 Spec 更新

**根据变更类型，生成对应 spec 更新**：

| 变更类型 | Spec 章节 | 更新内容 |
|----------|----------|---------|
| 新增 API | §4.1 对外接口 | 新增 API 条目 |
| 新增内部接口 | §4.2 内部接口 | 新增函数/方法 |
| 新增/修改模型 | §3 数据模型 | 实体字段变更 |
| 新增错误码 | §5.5 错误码 | 错误码定义 |
| 状态机变更 | §6 状态机 | 状态流转更新 |
| 核心逻辑变更 | §7 核心逻辑 | 流程更新 |

**更新生成示例**：

```markdown
# 生成的 Spec 更新片段

## §4.1 对外接口（新增）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/auth/oauth/callback | OAuth2 回调处理 |
| GET | /api/auth/oauth/providers | 获取支持的第三方登录列表 |

## §3.1 实体（新增）

**OAuthBinding**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | bigint | 主键 |
| user_id | bigint | 关联用户 |
| provider | string | 提供商 |
| provider_uid | string | 第三方用户 ID |
```

### 4) 冲突检测与合并

**检查 spec.md 是否被手动编辑**：

```bash
# 获取 spec.md 最近修改时间
stat docs/modules/auth/spec.md

# 如果 manual edit 时间在 MR 创建之后，可能存在冲突
```

**冲突处理策略**：

| 场景 | 处理方式 |
|------|---------|
| 无冲突 | 直接合并更新 |
| 同一章节都有修改 | 交互式确认，用户选择保留哪方 |
| 手动编辑补充了代码未体现的信息 | 保留手动编辑，追加代码变更 |

### 5) 回写 Spec

**应用更新到 module-spec.md**：

```bash
# 更新 spec.md 内容
# 更新「最近同步」时间戳
# 添加变更记录到 §8 变更记录
```

**变更记录格式**：
```markdown
## 8. 变更记录

| 日期 | feat/fix | 变更内容 |
|------|----------|---------|
| 2026-02-12 | feat #020 | 新增 OAuth 登录，含 GitHub/Google 支持 |
| 2026-02-10 | fix #021 | 修复 token 刷新过期问题 |
```

### 6) 检查 main-flows.md

**判断本次变更是否影响主流程**：

读取 `docs/spec/main-flows.md`（如不存在，提示用户先运行 `/spec-init`）。

**触发新增主流程的信号**：
- 新增了面向外部用户的核心 API（不是内部调用）
- 完成了一个独立的端到端用户场景（如注册→激活→登录）
- 修改了现有 P0 主流程中的步骤或接口

**触发更新已有主流程的信号**：
- 修改了 main-flows.md 中已有流程依赖的接口路径/参数
- 某个流程的步骤顺序发生了变化

**执行逻辑**：

```
Step 1: 读取 main-flows.md，列出当前所有主流程
Step 2: 对比本次代码变更
Step 3: 判断结果（以下三选一）
  A. 无影响 → 输出"main-flows.md 无需更新"，跳过
  B. 需要更新已有流程 → 列出受影响的流程 ID，自动更新步骤/接口描述
  C. 建议新增流程 → 输出建议，由用户确认后追加新条目
```

**新增流程格式**（追加到 main-flows.md）：

```markdown
## MF-{N}: {流程名称}

> 优先级：P0 / P1
> 关联 feat：feat-{iid}
> 最近更新：{date}

### 前置条件
- {条件}

### 步骤

| 步骤 | 操作 | 期望结果 |
|------|------|---------|
| 1 | {操作描述} | {期望} |
| 2 | {操作描述} | {期望} |

### 测试数据
- {测试数据说明}

### 清理
- {测试后清理步骤}
```

**注意**：不强制新增，由用户判断是否构成"主流程"。只有明确的端到端用户旅程才值得加入。

### 7) 提交与 MR（可选）

**创建提交**：
```bash
git add docs/modules/*/spec.md
git commit -m "docs: sync module spec with code changes

- auth: 新增 OAuth 相关接口和实体
- user: 用户表新增 email_verified 字段

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

**可选创建独立 MR**（spec-only 变更）：
```bash
# 创建分支
git checkout -b docs/sync-spec-from-feat-020

# 推送并创建 MR
git push -u origin docs/sync-spec-from-feat-020
# 创建 MR 链接到原功能 MR
```

### 8) 输出总结

```
════════════════════════════════════════════════════════════════
✅ Spec 同步完成

📄 更新的文档：
  📄 docs/modules/auth/spec.md
    - §3.1 新增 OAuthBinding 实体
    - §4.1 新增 2 个 API
    - §8 新增变更记录
  📄 docs/modules/user/spec.md
    - §3.1 users 表新增 email_verified 字段

📋 变更统计：
  | 模块 | API | 实体 | 字段 |
  |------|-----|------|------|
  | auth | +2  | +1   | +5   |
  | user | 0   | 0    | +1   |

⚠️ 注意事项：
  - spec.md 已更新「最近同步」时间戳
  - 如需提交，请运行：git commit -a -m "docs: sync spec"

📌 下一步建议：
  1. Review spec.md 更新内容
  2. 提交变更到版本控制
  3. 如需要，创建独立的 docs MR
════════════════════════════════════════════════════════════════
```

## 回写内容映射规则

### API 变更 → §4.1 对外接口

```
代码签名：
  POST /api/auth/oauth/callback
  func OAuthCallback(c *gin.Context)

提取到 spec：
  | POST | /api/auth/oauth/callback | OAuth2 回调处理 |
```

### 模型变更 → §3 数据模型

```
代码变更：
  type OAuthBinding struct {
      ID          int64
      UserID      int64
      Provider    string
      ProviderUID string
  }

提取到 spec：
  | 字段 | 类型 | 说明 |
  |------|------|------|
  | id | bigint | 主键 |
  | user_id | bigint | 关联用户 |
  | provider | string | 提供商 |
  | provider_uid | string | 第三方用户 ID |
```

### 错误码变更 → §5.5 错误码定义

```
代码中发现：
  errors.New("OAUTH_001: provider not supported")

提取到 spec：
  | 错误码 | 说明 |
  |--------|------|
  | OAUTH_001 | provider 不支持 |
```

## 辅助脚本

`scripts/diff-parser.sh` - 解析 diff 提取变更信息：

```bash
#!/bin/bash
# 解析 git diff，输出变更摘要
# 用法: ./diff-parser.sh [base_branch] [head_branch]

BASE=${1:-main}
HEAD=${2:-HEAD}

git diff "$BASE...$HEAD" --stat
git diff "$BASE...$HEAD" --name-only | grep -E '\.(go|py|js|ts)$'
```

## 使用场景

### 场景 1：开发完成后手动同步

```
用户：完成开发了，同步一下 spec
Claude：运行 spec-sync
  1. 分析 git diff
  2. 生成 spec 更新
  3. 应用更新
  4. 提示提交
```

### 场景 2：MR 合并前自动同步

```bash
# 在 CI 中运行（可选）
claude spec-sync --diff-from-main
```

### 场景 3：批量同步历史代码

```
用户：把现有代码同步到 spec
Claude：
  1. 遍历所有模块
  2. 分析代码结构
  3. 生成完整 spec（如 spec-extract）
```

## 注意事项

1. **活文档原则**：spec.md 是活文档，应定期同步
2. **增量更新**：优先增量更新，避免全量重写
3. **人工确认**：关键变更建议人工 review 后再提交
4. **版本兼容**：保留历史变更记录，便于追溯

## 资源

- 辅助脚本：`scripts/diff-parser.sh`
- Module Spec 模板：`../spec-init/assets/module-spec-template.md`
