---
name: release-e2e
description: |
  发版前主流程全量 E2E 验证，确保核心功能可用。

  触发条件：
  - "发版验证" / "release e2e" / "发版前测试"
  - "主流程验证" / "P0 流程测试"
  - 准备发版前的全量验证
  - 生产环境部署前检查

  关键词识别：发版、release、e2e验证、主流程、P0测试、上线检查
version: 0.1.0
---

# Release E2E

## 目的

- 发版前执行主流程全量 E2E 验证
- 按 P0/P1/P2 优先级排序执行
- 生成发版验证报告（GO/NO-GO 建议）
- 确保核心功能在发版前可用

## 输入

| 输入项 | 说明 | 来源 |
|--------|------|------|
| main-flows.md | 系统主流程定义 | `docs/spec/main-flows.md` |
| 环境配置 | 目标环境 URL | 用户输入或配置文件 |
| 优先级筛选 | 执行哪些优先级流程 | 默认 P0+P1 |

## 工作流

### 1) 读取主流程定义

**读取 `docs/spec/main-flows.md`**，提取所有主流程：

```
📋 主流程清单：

| ID | 流程名称 | 优先级 | 类型 | 状态 |
|----|---------|--------|------|------|
| MF-001 | 用户注册→登录→首页 | P0 | API+UI | ⏳ 待执行 |
| MF-002 | 创建工作流→执行→查看结果 | P0 | API | ⏳ 待执行 |
| MF-003 | 数据导入→处理→导出 | P1 | API | ⏳ 待执行 |
```

**按优先级排序**：P0 > P1 > P2，同优先级按 ID 排序。

### 2) 执行主流程

**逐个执行主流程**（API 类用 curl，UI 类用 agent-browser）：

#### API 类流程执行示例

```bash
# 准备测试数据
USERNAME="test_user_$(date +%s)"
PASSWORD="Test@12345"

# 步骤 1: 注册
curl -s -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\",\"email\":\"$USERNAME@test.com\"}" \
  -o /tmp/register_response.json

USER_ID=$(cat /tmp/register_response.json | jq -r '.data.user_id')

# 验证结果
if [ -z "$USER_ID" ] || [ "$USER_ID" = "null" ]; then
  echo "❌ 注册失败"
  exit 1
fi
echo "✅ 注册成功，user_id: $USER_ID"
```

#### UI 类流程执行示例

使用 `agent-browser` skill 执行：

```
/agent-browser "打开 $BASE_URL/login，输入用户名 $USERNAME 密码 $PASSWORD，点击登录按钮，
               验证是否跳转到 /dashboard 页面，截图保存"
```

### 3) 收集证据

**每个步骤收集**：
- 请求/响应数据（API）
- 截图（UI）
- 执行时间
- 实际结果 vs 期望结果

### 4) AI 判断

**对每个流程进行判断**：

| 结果 | 条件 |
|------|------|
| ✅ PASS | 所有步骤符合期望结果 |
| ⚠️ PARTIAL | 主要功能正常，有轻微问题 |
| ❌ FAIL | 关键步骤失败 |

### 5) 生成报告

**发版验证报告**：

```markdown
# Release E2E 验证报告

> 执行时间：2026-02-12 10:00:00
> 目标环境：https://staging.example.com
> 执行人：Claude

## 执行摘要

| 统计 | 数值 |
|------|------|
| 总流程数 | 3 |
| ✅ 通过 | 2 |
| ⚠️ 部分通过 | 0 |
| ❌ 失败 | 1 |
| 总耗时 | 5m 32s |

## 详细结果

### MF-001: 用户注册→登录→首页 (P0)

| 步骤 | 操作 | 结果 | 耗时 |
|------|------|------|------|
| 1 | POST /api/auth/register | ✅ PASS | 234ms |
| 2 | POST /api/auth/login | ✅ PASS | 189ms |
| 3 | GET /api/dashboard | ✅ PASS | 156ms |
| 4 | UI 登录流程 | ✅ PASS | 3.2s |
| 5 | UI 仪表盘验证 | ✅ PASS | 1.1s |

**结论**：✅ PASS

---

### MF-002: 创建工作流→执行→查看结果 (P0)

| 步骤 | 操作 | 结果 | 耗时 |
|------|------|------|------|
| 1 | POST /api/workflows | ❌ FAIL | 503ms |

**失败详情**：
- 期望：201 Created
- 实际：500 Internal Server Error
- 错误信息：`{"code":500,"message":"database connection timeout"}`

**结论**：❌ FAIL - 阻塞发版

---

## GO/NO-GO 建议

### 🔴 NO-GO - 不建议发版

**阻塞问题**：
1. MF-002 P0 流程失败 - 核心工作流功能不可用

**建议**：
- 修复数据库连接超时问题
- 重新执行 MF-002 验证
- 确认修复后再发版

---

*报告生成时间：2026-02-12 10:05:32*
```

### 6) 清理测试数据

**按流程「清理」节执行**：

```bash
# 删除测试用户
curl -s -X DELETE "$BASE_URL/api/admin/users/$USER_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# 删除测试工作流
curl -s -X DELETE "$BASE_URL/api/workflows/$WORKFLOW_ID" \
  -H "Authorization: Bearer $TOKEN"
```

### 7) 输出总结

```
════════════════════════════════════════════════════════════════
✅ Release E2E 验证完成

📊 执行结果：
  | 优先级 | 流程数 | 通过 | 失败 |
  |--------|--------|------|------|
  | P0     | 2      | 1    | 1    |
  | P1     | 1      | 1    | 0    |
  | P2     | 0      | 0    | 0    |

🎯 GO/NO-GO 建议：🔴 NO-GO
  阻塞问题：MF-002 核心工作流功能失败

📄 详细报告：docs/reports/release-e2e-20260212-100000.md

⚠️ 注意事项：
  - 已自动清理所有测试数据
  - 失败流程需修复后重新验证

📌 下一步：
  1. 查看详细报告确认失败原因
  2. 修复阻塞问题
  3. 重新执行 release-e2e
════════════════════════════════════════════════════════════════
```

## GO/NO-GO 决策规则

| 场景 | 建议 |
|------|------|
| 所有 P0 通过 | 🟢 GO |
| P0 失败 | 🔴 NO-GO |
| P0 通过，P1 部分失败 | 🟡 GO with caution |
| 仅 P2 失败 | 🟢 GO（记录问题） |

## 辅助脚本

`scripts/test-runner.sh` - 主流程测试执行：

```bash
#!/bin/bash
# 执行单个主流程测试
# 用法: ./test-runner.sh <main-flows.md> <flow-id> <base-url>

MAIN_FLOWS_FILE=$1
FLOW_ID=$2
BASE_URL=$3

# 解析 main-flows.md，提取指定流程
# 按步骤执行
# 输出 JSON 格式结果
```

## 配置

**环境变量**：

```bash
# .env.release-e2e
RELEASE_E2E_BASE_URL=https://staging.example.com
RELEASE_E2E_ADMIN_TOKEN=xxx
RELEASE_E2E_PRIORITY_FILTER=P0,P1  # 默认
```

**命令行参数**：

```bash
# 执行所有 P0
claude /release-e2e --priority=P0

# 执行指定流程
claude /release-e2e --flow=MF-001,MF-002

# 指定环境
claude /release-e2e --env=https://test.example.com
```

## 使用场景

### 场景 1：日常发版前验证

```
用户：准备发版，执行 release e2e
Claude：
  1. 读取 main-flows.md
  2. 执行所有 P0+P1 流程
  3. 生成 GO/NO-GO 报告
  4. 输出建议
```

### 场景 2：热修复后验证

```
用户：修复了 MF-002 的问题，验证一下
Claude：
  1. 仅执行 MF-002 流程
  2. 输出结果
```

### 场景 3：生产环境冒烟测试

```
用户：刚部署到生产，执行冒烟测试
Claude：
  1. 执行所有 P0 流程
  2. 快速验证核心功能
```

## 注意事项

1. **测试数据隔离**：使用时间戳生成唯一测试数据，避免冲突
2. **数据清理**：无论成功失败，都执行清理步骤
3. **超时处理**：API 调用设置超时（默认 30s）
4. **并发控制**：UI 类流程串行执行，避免浏览器冲突
5. **失败即停**：P0 流程失败立即停止，生成 NO-GO 报告

## 资源

- 辅助脚本：`scripts/test-runner.sh`
- Main Flows 模板：`docs/template-main-flows.md`
