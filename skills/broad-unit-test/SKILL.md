---
name: broad-unit-test
description: 大单元测试（Broad Unit Test / Sociable Unit Test）- 以 API Endpoint 为粒度，只 Mock 系统边界，验证业务契约。支持 Python、Go、Java。
---

# 大单元测试（Broad Unit Test）

> **核心理念**：测试完整的业务链路，而非孤立的函数。只在系统边界 Mock，让内部重构不破坏测试。

## 概述

**大单元测试**的粒度介于小单元测试和集成测试之间：

| 维度 | 小单元测试 | **大单元测试** ✅ | 集成测试 |
|------|-----------|---------------|---------|
| **测试粒度** | 单个函数/类 | **完整的 API Endpoint** | 整个系统 + 真实环境 |
| **Mock 范围** | Mock 所有依赖 | **只 Mock 数据库和外部 API** | 不 Mock / 极少 Mock |
| **执行速度** | 毫秒级 | **百毫秒级** | 秒/分钟级 |
| **重构友好度** | ❌ 低（改函数名就挂） | ✅ **高（只要业务不变就不挂）** | ✅ 极高 |
| **主要目的** | 验证算法逻辑 | **验证业务编排、流程控制** | 验证环境、网络、真实存储 |

**比喻**：
- 小单元测试 = 检查一颗"螺丝钉"的强度
- **大单元测试 = 检查一个"齿轮组"能否带着旁边的零件一起转动** ⚙️
- 集成测试 = 检查整台机器在真实环境下的运转

---

## 何时使用

### ✅ 适用场景

- 新增 API Endpoint（RESTful API、GraphQL、gRPC）
- 业务逻辑重构（保证业务契约不变）
- 修复业务流程 Bug（验证修复后的完整链路）
- 重构内部实现（合并/拆分函数、优化算法）
- 验证业务编排（多步骤流程、条件分支、重试逻辑）

### ❌ 不适用场景

- 纯工具函数（如 `formatDate()`、`validateEmail()`）→ 使用小单元测试
- 性能基准测试（如 QPS、延迟）→ 使用性能测试
- UI 交互测试（如点击、表单提交）→ 使用 E2E 测试
- 跨服务集成（如微服务间通信）→ 使用集成测试

---

## 核心原则

### 1. 测试粒度：以"业务功能节点"为单位

**测试的是一个完整的业务行为**，而非单个函数。

**示例**：

```
POST /vlog/generate  ← 这是一个测试单元

测试范围：
├── Controller（接口入口）
├── Service（业务逻辑）
│   ├── 参数组装
│   ├── Prompt 生成
│   ├── 重试逻辑
│   └── 错误处理
└── Model（领域模型）
```

### 2. Mock 策略：只在"系统边界"Mock

**✅ 需要 Mock 的**（系统边界）：
- 数据库操作（`db.save()`, `db.query()`）
- 外部 API（`ai_client.call()`, `payment_api.charge()`）
- 缓存服务（`redis.get()`, `redis.set()`）
- 消息队列（`mq.publish()`, `kafka.send()`）
- 文件系统（`fs.writeFile()`, `s3.upload()`）
- 时间/随机数（`time.now()`, `random.uuid()`）

**❌ 不需要 Mock 的**（内部实现）：
- Service 层的业务逻辑函数
- 工具函数（`utils.format_time()`）
- 内部类之间的调用
- 数据验证函数

### 3. 验证重点：业务契约而非实现细节

**✅ 应该验证**：
- 输入参数 A → 是否正确调用了数据库保存 B
- 异常情况下是否执行了重试逻辑
- 返回的 HTTP 状态码是否正确
- 业务流程的分支逻辑（if/else）是否正确
- 副作用（如发送邮件、记录日志）是否发生

**❌ 不应该验证**：
- 某个内部函数是否被调用了
- 某个变量的中间值是多少
- 函数内部用的是循环还是递归
- 函数的调用顺序（除非影响业务结果）

### 4. 重构友好：内部重构不破坏测试

**目标**：只要业务契约不变，测试就应该一直通过。

**允许的重构**（测试不应该挂）：
- 拆分函数：一个函数拆成三个
- 合并函数：三个函数合并成一个
- 改变实现：循环改成递归、同步改成异步
- 优化性能：O(n²) 改成 O(n log n)
- 重命名内部变量/函数

**不允许的变更**（测试应该挂）：
- 改变业务逻辑：重试 3 次改成 5 次
- 改变返回值：返回对象改成返回数组
- 改变副作用：不再发送邮件通知
- 改变 HTTP 状态码：200 改成 201

---

## 支持的语言和框架

### Python

| 框架 | 测试库 | 模板 |
|------|--------|------|
| Flask | pytest + pytest-flask + unittest.mock | [python-flask.md](templates/python-flask.md) |
| FastAPI | pytest + httpx + unittest.mock | [python-fastapi.md](templates/python-fastapi.md) |
| Django | pytest + pytest-django + unittest.mock | [python-django.md](templates/python-django.md) |

**示例**：[Python Vlog 生成接口](examples/python-vlog-api.md)

### Go

| 框架 | 测试库 | 模板 |
|------|--------|------|
| net/http | testing + httptest + gomock | [go-stdlib.md](templates/go-stdlib.md) |
| Gin | testing + httptest + gomock | [go-gin.md](templates/go-gin.md) |
| Echo | testing + httptest + gomock | [go-echo.md](templates/go-echo.md) |

**示例**：[Go 用户认证接口](examples/go-user-api.md)

### Java

| 框架 | 测试库 | 模板 |
|------|--------|------|
| Spring Boot | JUnit 5 + MockMvc + Mockito | [java-spring.md](templates/java-spring.md) |
| JAX-RS | JUnit 5 + Jersey Test + Mockito | [java-jaxrs.md](templates/java-jaxrs.md) |

**示例**：[Java 订单处理接口](examples/java-order-api.md)

---

## 测试模式

### AAA 模式（Arrange-Act-Assert）

```python
def test_vlog_generation():
    # Arrange（准备）- 设置 Mock 和测试数据
    mock_db = Mock()
    mock_ai = Mock()
    mock_ai.call.return_value = {"video_url": "https://example.com/video.mp4"}

    # Act（执行）- 调用完整的业务链路
    response = client.post("/vlog/generate", json={
        "user_id": "123",
        "template": "travel"
    })

    # Assert（断言）- 验证业务契约
    assert response.status_code == 200
    assert response.json["video_url"] == "https://example.com/video.mp4"
    mock_db.save.assert_called_once()  # 验证副作用
```

### Given-When-Then 模式

```go
func TestUserAuthentication(t *testing.T) {
    // Given（给定）- 准备测试环境
    mockDB := NewMockDB()
    mockDB.On("GetUser", "alice").Return(&User{ID: "123", Password: "hashed"}, nil)

    // When（当）- 执行业务操作
    req := httptest.NewRequest("POST", "/login", strings.NewReader(`{"username":"alice","password":"secret"}`))
    w := httptest.NewRecorder()
    LoginHandler(w, req)

    // Then（那么）- 验证期望结果
    assert.Equal(t, 200, w.Code)
    assert.Contains(t, w.Body.String(), "token")
}
```

---

## 快速开始

### 1. 识别测试粒度

**问自己**：
- 这个 API Endpoint 的业务目标是什么？
- 它涉及哪些 Service 层的逻辑？
- 它有哪些外部依赖（数据库、外部 API）？

### 2. 确定 Mock 边界

**使用工具**：
```bash
~/.claude/skills/broad-unit-test/tools/framework-detector.sh /path/to/project
```

**手动识别**：
- 查找数据库操作（`session.query()`, `db.Exec()`, `repository.save()`）
- 查找外部 API 调用（`requests.post()`, `http.Client.Do()`, `RestTemplate.exchange()`）
- 查找缓存操作（`redis.get()`, `cache.Set()`, `redisTemplate.opsForValue()`）

### 3. 编写测试

**选择对应的模板**：
- Python Flask → [templates/python-flask.md](templates/python-flask.md)
- Go Gin → [templates/go-gin.md](templates/go-gin.md)
- Java Spring Boot → [templates/java-spring.md](templates/java-spring.md)

**参考示例**：
- [Python Vlog 生成接口](examples/python-vlog-api.md)
- [Go 用户认证接口](examples/go-user-api.md)
- [Java 订单处理接口](examples/java-order-api.md)

### 4. 验证测试有效性

**运行测试并检查**：
```bash
# Python
pytest tests/test_vlog_api.py -v

# Go
go test -v ./...

# Java
mvn test
```

**质量检查**：
- [ ] 测试覆盖了所有业务分支（if/else、switch/case）
- [ ] 测试验证了所有副作用（数据库保存、外部 API 调用）
- [ ] 测试在内部重构后仍然通过
- [ ] Mock 只在系统边界，不 Mock 内部逻辑

---

## 常见问题

### Q1: 大单元测试和集成测试有什么区别？

| 维度 | 大单元测试 | 集成测试 |
|------|-----------|---------|
| 运行环境 | 进程内存（不需要真实数据库） | 真实环境（需要数据库、Redis 等） |
| 执行速度 | 快（百毫秒级） | 慢（秒/分钟级） |
| 适用场景 | 验证业务逻辑编排 | 验证系统间集成、网络通信 |
| CI/CD 运行频率 | 每次提交 | 每次合并到主分支 |

### Q2: 什么时候应该 Mock 内部函数？

**原则**：只有在内部函数调用系统边界时才 Mock。

**示例**：
```python
# ❌ 错误：Mock 内部业务逻辑
@patch('service.calculate_price')  # 不应该 Mock
def test_order(mock_calc):
    ...

# ✅ 正确：Mock 系统边界
@patch('database.save_order')  # 应该 Mock
def test_order(mock_db):
    ...
```

### Q3: 如何避免测试变得太复杂？

**征兆**：
- Mock 设置占测试代码的 >50%
- 需要 Mock 10+ 个依赖
- 测试代码比被测代码还长

**解决方案**：
1. **降低粒度**：如果业务链路太长，拆分成多个 API Endpoint
2. **使用测试工具类**：提取通用的 Mock 设置到 `conftest.py` / `test_helper.go` / `TestBase.java`
3. **考虑集成测试**：如果 Mock 太复杂，可能真实环境测试更简单

### Q4: 大单元测试能替代小单元测试吗？

**不能完全替代**，两者互补：

| 场景 | 使用大单元测试 | 使用小单元测试 |
|------|--------------|--------------|
| API Endpoint 业务逻辑 | ✅ | - |
| 复杂算法（如排序、加密） | - | ✅ |
| 纯工具函数（如日期格式化） | - | ✅ |
| 业务流程编排 | ✅ | - |
| 边界条件（如空值、极大值） | ✅（业务层面） | ✅（函数层面） |

**推荐策略（测试奖杯模型）**：

> 传统「测试金字塔」适用于类库/框架开发，但对于业务系统，Kent C. Dodds 的「测试奖杯」(Testing Trophy) 更合适——服务层测试占主体。

- **70% 大单元测试**（覆盖业务契约）← 奖杯主体，最大价值区域
- **20% 小单元测试**（覆盖复杂算法和工具函数）
- **10% 集成测试 / E2E**（覆盖关键业务流程）

---

## 参考资料

- [Mock 边界识别指南](references/mock-boundaries.md)
- [测试模式详解](references/test-patterns.md)
- [与小单元测试、集成测试的对比](references/comparison.md)

---

## 快速参考卡

| 要素 | 要点 |
|------|------|
| **测试粒度** | API Endpoint（Controller → Service → Model） |
| **Mock 范围** | 只 Mock 系统边界（数据库、外部 API、缓存） |
| **验证重点** | 业务契约（输入 → 输出 → 副作用） |
| **重构友好** | 内部重构不破坏测试 |
| **执行速度** | 百毫秒级（快于集成测试，慢于小单元测试） |
| **主要价值** | 敢于重构、防止业务逻辑回归 |

---

**Remember**: 大单元测试让你锁定业务契约，自由重构内部实现。测试的是"齿轮组"，而非"螺丝钉"。⚙️
