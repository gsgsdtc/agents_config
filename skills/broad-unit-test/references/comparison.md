# 大单元测试 vs 小单元测试 vs 集成测试

> **核心区别**：测试粒度、Mock 策略、重构友好度

## 快速对比表

| 维度 | 小单元测试 | **大单元测试** ⚙️ | 集成测试 |
|------|-----------|---------------|---------|
| **测试粒度** | 单个函数/类 | **完整的 API Endpoint** | 整个系统 + 真实环境 |
| **Mock 范围** | Mock 所有依赖 | **只 Mock 数据库和外部 API** | 不 Mock / 极少 Mock |
| **测试范围** | Controller → Service → Model | **Controller → Service → Model** | **所有组件 + 真实存储** |
| **执行速度** | ⚡ 极快（毫秒级） | ⚡ 快（百毫秒级） | 🐢 慢（秒/分钟级） |
| **重构友好度** | ❌ 低（改函数名就挂） | ✅ **高（只要业务不变就不挂）** | ✅ 极高 |
| **主要目的** | 验证算法逻辑 | **验证业务编排、流程控制** | 验证环境、网络、真实存储 |
| **维护成本** | ❌ 高（代码改动频繁需要更新） | ✅ 低（只改业务契约时更新） | ✅ 极低 |
| **CI/CD 频率** | 每次提交 | 每次提交 | 每次合并到主分支 |

---

## 详细对比

### 1. 测试粒度

#### 小单元测试
```python
# 测试单个函数
def test_calculate_price():
    price = calculate_price(100, 0.2)  # 只测试这个函数
    assert price == 120
```

#### 大单元测试 ⚙️
```python
# 测试完整的 API Endpoint
def test_create_order_endpoint():
    response = client.post('/api/orders', json={
        "product_id": "123",
        "quantity": 2
    })
    # 测试整个业务链路：参数验证 → 库存检查 → 计算价格 → 保存订单
    assert response.status_code == 201
    assert response.json["total_price"] == 240
```

#### 集成测试
```python
# 测试整个系统（包括真实数据库、消息队列）
def test_order_fulfillment_flow():
    # 创建订单 → 支付 → 库存扣减 → 发货通知
    # 使用真实数据库、真实消息队列
    order = create_order_via_api(...)
    payment = process_payment_via_api(...)
    assert order.status == "fulfilled"
```

---

### 2. Mock 策略

#### 小单元测试
```python
@patch('services.price_calculator')  # Mock 内部业务逻辑
@patch('services.inventory_checker')  # Mock 内部业务逻辑
@patch('database.save_order')         # Mock 数据库
def test_order_service(mock_db, mock_inventory, mock_calc):
    # Mock 所有依赖
    ...
```

**问题**：
- Mock 太多，测试变得复杂
- 改变内部实现（如合并两个函数），测试就挂

#### 大单元测试 ⚙️
```python
@patch('database.save_order')         # 只 Mock 数据库
@patch('external_api.payment_service') # 只 Mock 外部 API
def test_order_endpoint(mock_db, mock_payment):
    # 内部业务逻辑（price_calculator、inventory_checker）使用真实代码
    response = client.post('/api/orders', ...)
    ...
```

**优势**：
- Mock 少，测试简洁
- 内部重构不破坏测试

#### 集成测试
```python
def test_order_flow():
    # 不 Mock，使用真实数据库、真实消息队列
    response = client.post('/api/orders', ...)
    ...
```

**优势**：
- 最真实的测试
- 发现集成问题

**劣势**：
- 慢
- 需要真实环境

---

### 3. 重构友好度

#### 小单元测试 ❌

**场景**：重构内部实现（拆分函数）

```python
# 原实现
def process_order(order):
    validate_order(order)
    calculate_price(order)
    save_order(order)

# 测试
@patch('services.validate_order')
@patch('services.calculate_price')
@patch('services.save_order')
def test_process_order(mock_save, mock_calc, mock_validate):
    process_order(order)
    mock_validate.assert_called_once()  # ✅ 测试通过
    mock_calc.assert_called_once()
    mock_save.assert_called_once()
```

**重构后**：

```python
# 新实现：合并 validate_order 和 calculate_price
def process_order(order):
    price = validate_and_calculate(order)  # 合并了两个函数
    save_order(order)
```

**结果**：
- ❌ 测试挂了！因为 Mock 的函数不再被调用
- 需要修改测试代码

#### 大单元测试 ✅

**场景**：相同的重构

```python
# 测试（大单元测试）
@patch('database.save_order')
def test_create_order_endpoint(mock_db):
    response = client.post('/api/orders', json={
        "product_id": "123",
        "quantity": 2
    })
    assert response.status_code == 201
    assert response.json["total_price"] == 240
    mock_db.assert_called_once()
```

**重构后**：

```python
# 新实现：合并 validate_order 和 calculate_price
def process_order(order):
    price = validate_and_calculate(order)  # 合并了两个函数
    save_order(order)
```

**结果**：
- ✅ 测试仍然通过！因为业务契约没变（输入 → 输出 → 副作用）
- 不需要修改测试代码

---

### 4. 测试覆盖的内容

#### 小单元测试
```python
# 只测试单个函数的逻辑
def test_calculate_discount():
    # ✅ 测试：折扣计算逻辑
    # ❌ 不测试：折扣如何与订单流程集成
    assert calculate_discount(100, "VIP") == 20
```

#### 大单元测试 ⚙️
```python
# 测试完整的业务流程
def test_create_order_with_discount():
    # ✅ 测试：参数验证 → 折扣计算 → 价格计算 → 订单保存
    response = client.post('/api/orders', json={
        "product_id": "123",
        "user_type": "VIP",
        "quantity": 2
    })
    assert response.status_code == 201
    assert response.json["discount"] == 20
    assert response.json["total_price"] == 180  # 原价 200 - 折扣 20
```

#### 集成测试
```python
# 测试整个系统的集成
def test_order_and_inventory_integration():
    # ✅ 测试：订单创建 → 库存扣减 → 数据库一致性
    # 使用真实数据库
    initial_stock = get_stock("123")
    response = client.post('/api/orders', ...)
    final_stock = get_stock("123")
    assert final_stock == initial_stock - 2
```

---

### 5. 何时使用

#### 小单元测试
**适用场景**：
- ✅ 纯工具函数（如 `formatDate()`, `validateEmail()`）
- ✅ 复杂算法（如排序、加密、数学计算）
- ✅ 边界条件测试（如空值、极大值、负数）

**不适用场景**：
- ❌ 业务流程编排
- ❌ API Endpoint
- ❌ 多步骤操作

#### 大单元测试 ⚙️
**适用场景**：
- ✅ API Endpoint（RESTful API、GraphQL、gRPC）
- ✅ 业务流程编排（多步骤流程、条件分支）
- ✅ 业务逻辑重构（保证业务契约不变）
- ✅ 重试逻辑、错误处理、状态转换

**不适用场景**：
- ❌ 纯工具函数
- ❌ 性能基准测试
- ❌ UI 交互测试

#### 集成测试
**适用场景**：
- ✅ 跨服务集成（微服务间通信）
- ✅ 数据库一致性（事务、并发）
- ✅ 消息队列（发布/订阅）
- ✅ 关键业务流程（端到端）

**不适用场景**：
- ❌ 单个函数逻辑
- ❌ 快速反馈需求
- ❌ 环境不可用时

---

### 6. 测试维护成本

#### 小单元测试 ❌
**维护成本高**，因为：
- 代码重构频繁需要更新测试
- Mock 设置复杂，容易出错
- 测试数量多，维护工作量大

**示例**：
- 重命名函数 → 需要更新 10+ 个测试
- 合并两个函数 → 需要删除旧测试，重写新测试

#### 大单元测试 ✅
**维护成本低**，因为：
- 只改业务契约时才需要更新
- Mock 少，测试简洁
- 内部重构不影响测试

**示例**：
- 重命名函数 → 测试不需要改
- 合并两个函数 → 测试不需要改
- 改变业务逻辑（如重试 3 次改成 5 次）→ 测试需要改

#### 集成测试 ✅
**维护成本极低**，因为：
- 测试真实行为，不关心实现
- 数量少（只测关键流程）

---

### 7. CI/CD 集成

#### 小单元测试
```yaml
# 每次提交都运行
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: npm test  # 运行所有小单元测试
```

**优势**：
- 快（秒级）
- 提供快速反馈

**劣势**：
- 不测试集成问题

#### 大单元测试 ⚙️
```yaml
# 每次提交都运行
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - run: pytest tests/  # 运行大单元测试
```

**优势**：
- 相对快（10-30 秒）
- 测试业务逻辑
- 发现集成问题

**劣势**：
- 比小单元测试慢一点

#### 集成测试
```yaml
# 只在合并到主分支时运行
on:
  push:
    branches: [main]
jobs:
  integration-test:
    runs-on: ubuntu-latest
    steps:
      - run: docker-compose up -d  # 启动真实环境
      - run: pytest tests/integration/
```

**优势**：
- 最真实的测试

**劣势**：
- 慢（分钟级）
- 需要真实环境

---

## 推荐策略

### 测试奖杯（Testing Trophy）

> 传统的「测试金字塔」强调底层单元测试最多，但对于业务系统而言，「测试奖杯」(Kent C. Dodds) 或「测试蜂巢」(Spotify) 模型更合适——服务层/API 层测试占主体。

```
        ___
       /   \      E2E（10%）- 关键业务流程端到端验证
      /_____\
     /       \
    /         \
   /           \   大单元测试（70%）⚙️ - API Endpoint 业务逻辑
  /             \  【奖杯主体 - 最大价值区域】
 /_______________\
        ||
        ||         小单元测试（20%）- 复杂算法和工具函数
       ====
```

**为什么不是金字塔？**

| 模型 | 适用场景 | 特点 |
|------|---------|------|
| 测试金字塔 | 类库、框架、工具包 | 底层单元测试为主，API 稳定 |
| **测试奖杯** ✅ | **业务系统、Web 应用** | **服务层测试为主，业务逻辑变化频繁** |
| 测试蜂巢 | 微服务架构 | 强调服务间契约测试 |

**关键洞察**：业务系统的核心价值在于「业务逻辑的正确编排」，而非「单个函数的正确实现」。大单元测试直接验证业务契约，是投入产出比最高的测试层级。

### 具体建议

| 测试类型 | 占比 | 适用场景 |
|---------|------|---------|
| 小单元测试 | 20% | 纯工具函数、复杂算法 |
| **大单元测试** ⚙️ | **70%** | **API Endpoint、业务流程** |
| 集成测试 | 10% | 关键业务流程、跨服务集成 |

### 示例项目

```
tests/
├── unit/                      # 20% - 小单元测试
│   ├── test_utils.py          # 工具函数
│   └── test_validators.py     # 验证器
├── broad_unit/                # 70% - 大单元测试 ⚙️
│   ├── test_order_api.py      # 订单 API
│   ├── test_user_api.py       # 用户 API
│   └── test_payment_api.py    # 支付 API
└── integration/               # 10% - 集成测试
    └── test_order_flow.py     # 完整订单流程
```

---

## 总结

| 特性 | 小单元测试 | 大单元测试 ⚙️ | 集成测试 |
|------|-----------|------------|---------|
| **速度** | ⚡⚡⚡ | ⚡⚡ | ⚡ |
| **重构友好** | ❌ | ✅ | ✅ |
| **维护成本** | ❌ 高 | ✅ 低 | ✅ 极低 |
| **发现问题能力** | 算法错误 | 业务逻辑错误 | 集成问题 |
| **推荐占比** | 20% | **70%** | 10% |

**Remember**: 大单元测试是最实用的测试粒度，平衡了速度、维护成本和测试覆盖！⚙️
