# Python Flask 大单元测试模板

> **适用于**：Flask 应用的 API Endpoint 测试

## 测试环境配置

### 依赖安装

```bash
pip install pytest pytest-flask pytest-mock
```

### 测试配置（`conftest.py`）

```python
import pytest
from unittest.mock import Mock, patch
from your_app import create_app

@pytest.fixture
def app():
    """创建测试应用"""
    app = create_app(testing=True)
    app.config.update({
        "TESTING": True,
        "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",  # 测试用内存数据库
    })
    return app

@pytest.fixture
def client(app):
    """创建测试客户端"""
    return app.test_client()

@pytest.fixture
def mock_db(mocker):
    """Mock 数据库操作"""
    return mocker.patch('your_app.database.db')

@pytest.fixture
def mock_redis(mocker):
    """Mock Redis 缓存"""
    return mocker.patch('your_app.cache.redis_client')

@pytest.fixture
def mock_external_api(mocker):
    """Mock 外部 API"""
    return mocker.patch('your_app.services.external_api_client')
```

---

## 测试模板

### 基础模板（AAA 模式）

```python
import pytest
from unittest.mock import Mock, patch

class TestVlogGenerationAPI:
    """测试 Vlog 生成 API - 完整业务链路"""

    def test_successful_vlog_generation(self, client, mock_db, mock_external_api):
        """
        测试场景：成功生成 Vlog

        业务链路：
        1. 接收用户请求
        2. 验证参数
        3. 调用 AI API 生成视频
        4. 保存到数据库
        5. 返回视频 URL
        """
        # Arrange（准备）- 设置 Mock 行为
        mock_external_api.generate_video.return_value = {
            "video_url": "https://cdn.example.com/video123.mp4",
            "duration": 30,
            "status": "completed"
        }
        mock_db.session.add = Mock()
        mock_db.session.commit = Mock()

        # Act（执行）- 调用完整的 API
        response = client.post('/api/vlog/generate', json={
            "user_id": "user_123",
            "template": "travel",
            "clips": ["clip1.mp4", "clip2.mp4"],
            "music": "happy_beat.mp3"
        })

        # Assert（断言）- 验证业务契约
        assert response.status_code == 200
        data = response.get_json()
        assert data["video_url"] == "https://cdn.example.com/video123.mp4"
        assert data["duration"] == 30

        # 验证副作用：数据库保存
        mock_db.session.add.assert_called_once()
        mock_db.session.commit.assert_called_once()

        # 验证副作用：AI API 调用
        mock_external_api.generate_video.assert_called_once_with(
            template="travel",
            clips=["clip1.mp4", "clip2.mp4"],
            music="happy_beat.mp3"
        )

    def test_retry_on_ai_api_failure(self, client, mock_db, mock_external_api):
        """
        测试场景：AI API 失败后重试逻辑

        验证重点：
        - 第一次失败后是否重试
        - 重试成功后返回正确结果
        """
        # Arrange - AI API 前 2 次失败，第 3 次成功
        mock_external_api.generate_video.side_effect = [
            Exception("AI API timeout"),
            Exception("AI API rate limit"),
            {"video_url": "https://cdn.example.com/video123.mp4", "duration": 30}
        ]

        # Act
        response = client.post('/api/vlog/generate', json={
            "user_id": "user_123",
            "template": "travel",
            "clips": ["clip1.mp4"]
        })

        # Assert - 验证重试 3 次
        assert response.status_code == 200
        assert mock_external_api.generate_video.call_count == 3

    def test_validation_error_on_invalid_template(self, client):
        """
        测试场景：无效模板参数

        验证重点：
        - 参数验证逻辑
        - 返回 400 状态码
        - 错误消息清晰
        """
        # Act - 发送无效模板
        response = client.post('/api/vlog/generate', json={
            "user_id": "user_123",
            "template": "invalid_template",  # 不存在的模板
            "clips": ["clip1.mp4"]
        })

        # Assert
        assert response.status_code == 400
        data = response.get_json()
        assert "error" in data
        assert "invalid template" in data["error"].lower()

    def test_database_error_handling(self, client, mock_db, mock_external_api):
        """
        测试场景：数据库保存失败

        验证重点：
        - 数据库异常处理
        - 返回 500 状态码
        - 事务回滚
        """
        # Arrange - 数据库保存失败
        mock_external_api.generate_video.return_value = {
            "video_url": "https://cdn.example.com/video123.mp4",
            "duration": 30
        }
        mock_db.session.commit.side_effect = Exception("Database connection lost")

        # Act
        response = client.post('/api/vlog/generate', json={
            "user_id": "user_123",
            "template": "travel",
            "clips": ["clip1.mp4"]
        })

        # Assert
        assert response.status_code == 500
        data = response.get_json()
        assert "error" in data

        # 验证事务回滚
        mock_db.session.rollback.assert_called_once()
```

---

## Mock 策略

### 1. Mock 数据库操作

```python
@pytest.fixture
def mock_db_operations(mocker):
    """Mock SQLAlchemy 数据库操作"""
    mock_db = mocker.patch('your_app.extensions.db')

    # Mock 查询操作
    mock_query = Mock()
    mock_db.session.query.return_value = mock_query
    mock_query.filter_by.return_value = mock_query
    mock_query.first.return_value = {"id": 1, "name": "test"}

    # Mock 写操作
    mock_db.session.add = Mock()
    mock_db.session.commit = Mock()
    mock_db.session.rollback = Mock()

    return mock_db

def test_with_db_mock(client, mock_db_operations):
    response = client.post('/api/users', json={"name": "Alice"})
    assert response.status_code == 201
    mock_db_operations.session.add.assert_called_once()
```

### 2. Mock 外部 API

```python
@pytest.fixture
def mock_ai_api(mocker):
    """Mock 外部 AI API"""
    mock_client = mocker.patch('your_app.services.ai_client.AIClient')
    mock_instance = mock_client.return_value

    # 设置默认返回值
    mock_instance.generate.return_value = {
        "result": "success",
        "data": {"video_url": "https://example.com/video.mp4"}
    }

    return mock_instance

def test_with_ai_api_mock(client, mock_ai_api):
    response = client.post('/api/vlog/generate', json={
        "template": "travel",
        "clips": ["clip1.mp4"]
    })
    assert response.status_code == 200
    mock_ai_api.generate.assert_called_once()
```

### 3. Mock Redis 缓存

```python
@pytest.fixture
def mock_redis(mocker):
    """Mock Redis 缓存操作"""
    mock_redis_client = mocker.patch('your_app.cache.redis_client')

    # 模拟缓存数据
    cache_data = {}

    def get_side_effect(key):
        return cache_data.get(key)

    def set_side_effect(key, value, ex=None):
        cache_data[key] = value

    mock_redis_client.get.side_effect = get_side_effect
    mock_redis_client.set.side_effect = set_side_effect

    return mock_redis_client

def test_with_cache_mock(client, mock_redis):
    # 第一次请求 - 缓存未命中
    response1 = client.get('/api/users/123')
    assert mock_redis.get.call_count == 1
    assert mock_redis.set.call_count == 1

    # 第二次请求 - 缓存命中
    response2 = client.get('/api/users/123')
    assert mock_redis.get.call_count == 2
```

---

## 高级模式

### 参数化测试（多场景覆盖）

```python
import pytest

@pytest.mark.parametrize("template,clips,expected_status", [
    ("travel", ["clip1.mp4"], 200),  # 正常场景
    ("food", ["clip1.mp4", "clip2.mp4"], 200),  # 多个视频片段
    ("invalid", ["clip1.mp4"], 400),  # 无效模板
    ("travel", [], 400),  # 缺少视频片段
    ("travel", ["clip1.mp4"] * 100, 400),  # 视频片段过多
])
def test_vlog_generation_scenarios(client, mock_db, mock_external_api,
                                   template, clips, expected_status):
    """
    参数化测试多种场景
    """
    if expected_status == 200:
        mock_external_api.generate_video.return_value = {
            "video_url": "https://example.com/video.mp4"
        }

    response = client.post('/api/vlog/generate', json={
        "user_id": "user_123",
        "template": template,
        "clips": clips
    })

    assert response.status_code == expected_status
```

### 异步操作测试

```python
import pytest
import asyncio

@pytest.mark.asyncio
async def test_async_vlog_generation(client, mock_external_api):
    """
    测试异步 Vlog 生成
    """
    # Mock 异步 API 调用
    mock_external_api.generate_video_async.return_value = asyncio.Future()
    mock_external_api.generate_video_async.return_value.set_result({
        "video_url": "https://example.com/video.mp4"
    })

    response = client.post('/api/vlog/generate_async', json={
        "user_id": "user_123",
        "template": "travel",
        "clips": ["clip1.mp4"]
    })

    assert response.status_code == 202  # Accepted
    data = response.get_json()
    assert "task_id" in data
```

### 测试辅助函数

```python
# test_helpers.py

def create_mock_user(user_id="user_123", name="Alice", premium=False):
    """创建 Mock 用户对象"""
    return {
        "id": user_id,
        "name": name,
        "premium": premium,
        "created_at": "2024-01-01T00:00:00Z"
    }

def create_mock_vlog_request(template="travel", clips=None):
    """创建 Mock Vlog 请求"""
    if clips is None:
        clips = ["clip1.mp4"]
    return {
        "user_id": "user_123",
        "template": template,
        "clips": clips,
        "music": "default.mp3"
    }

def assert_vlog_response(response, expected_status=200):
    """验证 Vlog 响应格式"""
    assert response.status_code == expected_status
    if expected_status == 200:
        data = response.get_json()
        assert "video_url" in data
        assert "duration" in data
        assert data["video_url"].startswith("https://")
```

---

## 最佳实践

### ✅ DO

1. **测试完整的业务链路**，而非单个函数
2. **只 Mock 系统边界**（数据库、外部 API）
3. **验证副作用**（数据库保存、外部 API 调用）
4. **测试业务分支**（if/else、switch/case）
5. **使用清晰的测试名称**（描述业务场景）
6. **参数化测试**覆盖多种输入场景

### ❌ DON'T

1. **不要 Mock 内部业务逻辑函数**
2. **不要测试实现细节**（如函数调用顺序）
3. **不要忽略错误处理测试**
4. **不要让测试依赖执行顺序**
5. **不要在测试中使用真实数据库**（除非是集成测试）

---

## 运行测试

```bash
# 运行所有测试
pytest

# 运行特定文件
pytest tests/test_vlog_api.py

# 运行特定测试
pytest tests/test_vlog_api.py::TestVlogGenerationAPI::test_successful_vlog_generation

# 运行并显示覆盖率
pytest --cov=your_app --cov-report=html

# 运行并显示详细输出
pytest -v

# 运行并显示 print 输出
pytest -s
```

---

## 常见问题

### Q: 如何 Mock Flask-SQLAlchemy 的查询？

```python
@pytest.fixture
def mock_user_query(mocker):
    mock_db = mocker.patch('your_app.extensions.db')
    mock_query = Mock()
    mock_db.session.query.return_value = mock_query
    mock_query.filter_by.return_value = mock_query
    mock_query.first.return_value = {
        "id": 1,
        "name": "Alice",
        "email": "alice@example.com"
    }
    return mock_query
```

### Q: 如何测试需要认证的 API？

```python
@pytest.fixture
def auth_headers():
    """返回认证头"""
    return {
        "Authorization": "Bearer test_token_123"
    }

def test_protected_endpoint(client, auth_headers, mock_db):
    response = client.post('/api/vlog/generate',
                          json={"template": "travel"},
                          headers=auth_headers)
    assert response.status_code == 200
```

### Q: 如何测试文件上传？

```python
from io import BytesIO

def test_file_upload(client, mock_s3):
    """测试文件上传到 S3"""
    data = {
        'file': (BytesIO(b'test video content'), 'test.mp4')
    }

    response = client.post('/api/upload',
                          data=data,
                          content_type='multipart/form-data')

    assert response.status_code == 200
    mock_s3.upload_file.assert_called_once()
```

---

**Remember**: 大单元测试关注业务契约，而非实现细节。测试的是"齿轮组"，而非"螺丝钉"。⚙️
