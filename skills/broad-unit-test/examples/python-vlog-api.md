# Python Vlog 生成 API 大单元测试示例

> **场景**：测试一个 Flask API Endpoint，用于生成 Vlog 视频

## 业务场景

**API Endpoint**: `POST /api/vlog/generate`

**业务流程**：
1. 接收用户请求（用户 ID、模板、视频片段）
2. 参数验证
3. 调用 AI API 生成视频
4. 失败时重试 3 次
5. 保存到数据库
6. 返回视频 URL

**系统边界**（需要 Mock）：
- 数据库操作（`db.session.add()`, `db.session.commit()`）
- AI API 调用（`ai_client.generate_video()`）

**内部逻辑**（不 Mock）：
- 参数验证
- Prompt 组装
- 重试逻辑
- 错误处理

---

## 被测试的代码

### Controller（`app/controllers/vlog_controller.py`）

```python
from flask import Blueprint, request, jsonify
from app.services.vlog_service import VlogService
from app.database import db

vlog_bp = Blueprint('vlog', __name__)
vlog_service = VlogService()

@vlog_bp.route('/api/vlog/generate', methods=['POST'])
def generate_vlog():
    """生成 Vlog 视频"""
    try:
        data = request.get_json()

        # 参数验证（不 Mock）
        user_id = data.get('user_id')
        template = data.get('template')
        clips = data.get('clips', [])

        if not user_id or not template or not clips:
            return jsonify({"error": "Missing required fields"}), 400

        # 调用业务逻辑层（不 Mock）
        result = vlog_service.generate_vlog(user_id, template, clips)

        return jsonify(result), 200

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        return jsonify({"error": "Internal server error"}), 500
```

### Service（`app/services/vlog_service.py`）

```python
from app.models import Vlog
from app.database import db
from app.services.ai_client import AIClient
import time

class VlogService:
    def __init__(self):
        self.ai_client = AIClient()

    def generate_vlog(self, user_id, template, clips):
        """生成 Vlog（包含重试逻辑）"""
        # 参数验证（业务逻辑，不 Mock）
        if template not in ['travel', 'food', 'daily', 'sports']:
            raise ValueError("invalid template")

        if len(clips) == 0:
            raise ValueError("clips cannot be empty")

        if len(clips) > 50:
            raise ValueError("too many clips")

        # 调用 AI API（需要 Mock）- 重试 3 次
        video_data = None
        max_retries = 3

        for attempt in range(max_retries):
            try:
                video_data = self.ai_client.generate_video(template, clips)
                break
            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                time.sleep(1)

        # 保存到数据库（需要 Mock）
        vlog = Vlog(
            user_id=user_id,
            template=template,
            video_url=video_data['video_url'],
            duration=video_data['duration']
        )

        db.session.add(vlog)
        db.session.commit()

        return {
            "video_url": video_data['video_url'],
            "duration": video_data['duration']
        }
```

---

## 大单元测试

### 测试代码（`tests/test_vlog_api.py`）

```python
import pytest
from unittest.mock import Mock, patch
from app import create_app

class TestVlogGenerationAPI:
    """测试 Vlog 生成 API - 完整业务链路"""

    @pytest.fixture
    def client(self):
        """创建测试客户端"""
        app = create_app(testing=True)
        return app.test_client()

    @pytest.fixture
    def mock_db(self, mocker):
        """Mock 数据库操作"""
        return mocker.patch('app.database.db')

    @pytest.fixture
    def mock_ai_client(self, mocker):
        """Mock AI API"""
        return mocker.patch('app.services.ai_client.AIClient')

    def test_successful_vlog_generation(self, client, mock_db, mock_ai_client):
        """
        测试场景：成功生成 Vlog

        业务链路：
        1. 接收用户请求
        2. 验证参数（travel 是有效模板）✓
        3. 调用 AI API 生成视频 ✓
        4. 保存到数据库 ✓
        5. 返回视频 URL ✓

        验证重点：
        - HTTP 状态码 200
        - 返回正确的 video_url 和 duration
        - AI API 被调用 1 次（不重试）
        - 数据库保存被调用 1 次
        """
        # Arrange - 设置 Mock 行为
        mock_ai_instance = mock_ai_client.return_value
        mock_ai_instance.generate_video.return_value = {
            "video_url": "https://cdn.example.com/video123.mp4",
            "duration": 30,
            "status": "completed"
        }

        mock_db.session.add = Mock()
        mock_db.session.commit = Mock()

        # Act - 调用完整的 API
        response = client.post('/api/vlog/generate', json={
            "user_id": "user_123",
            "template": "travel",
            "clips": ["clip1.mp4", "clip2.mp4"],
            "music": "happy_beat.mp3"
        })

        # Assert - 验证业务契约
        assert response.status_code == 200
        data = response.get_json()
        assert data["video_url"] == "https://cdn.example.com/video123.mp4"
        assert data["duration"] == 30

        # 验证副作用：AI API 调用
        mock_ai_instance.generate_video.assert_called_once_with(
            "travel",
            ["clip1.mp4", "clip2.mp4"]
        )

        # 验证副作用：数据库保存
        mock_db.session.add.assert_called_once()
        mock_db.session.commit.assert_called_once()

    def test_retry_on_ai_api_failure(self, client, mock_db, mock_ai_client):
        """
        测试场景：AI API 失败后重试逻辑

        业务链路：
        1. 第 1 次调用 AI API → 失败（超时）
        2. 第 2 次调用 AI API → 失败（限流）
        3. 第 3 次调用 AI API → 成功
        4. 保存到数据库
        5. 返回视频 URL

        验证重点：
        - 重试逻辑正确执行（3 次）
        - 最终返回成功结果
        - AI API 被调用 3 次
        """
        # Arrange - AI API 前 2 次失败，第 3 次成功
        mock_ai_instance = mock_ai_client.return_value
        mock_ai_instance.generate_video.side_effect = [
            Exception("AI API timeout"),
            Exception("AI API rate limit"),
            {
                "video_url": "https://cdn.example.com/video123.mp4",
                "duration": 30
            }
        ]

        mock_db.session.add = Mock()
        mock_db.session.commit = Mock()

        # Act
        response = client.post('/api/vlog/generate', json={
            "user_id": "user_123",
            "template": "travel",
            "clips": ["clip1.mp4"]
        })

        # Assert - 验证重试 3 次
        assert response.status_code == 200
        assert mock_ai_instance.generate_video.call_count == 3

        # 验证最终成功
        data = response.get_json()
        assert data["video_url"] == "https://cdn.example.com/video123.mp4"

    def test_validation_error_on_invalid_template(self, client):
        """
        测试场景：无效模板参数

        业务链路：
        1. 接收用户请求
        2. 参数验证失败（invalid_template 不是有效模板）→ 返回 400

        验证重点：
        - HTTP 状态码 400
        - 返回错误消息
        - 不应该调用 AI API
        - 不应该保存到数据库

        注意：不需要 Mock，因为在参数验证阶段就返回了
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

    def test_validation_error_on_empty_clips(self, client):
        """
        测试场景：视频片段为空

        验证重点：
        - 业务规则验证（clips 不能为空）
        - 返回 400 状态码
        """
        response = client.post('/api/vlog/generate', json={
            "user_id": "user_123",
            "template": "travel",
            "clips": []  # 空数组
        })

        assert response.status_code == 400
        data = response.get_json()
        assert "clips cannot be empty" in data["error"]

    def test_validation_error_on_too_many_clips(self, client):
        """
        测试场景：视频片段过多

        验证重点：
        - 业务规则验证（clips 不能超过 50 个）
        - 返回 400 状态码
        """
        # 构造 51 个视频片段
        clips = [f"clip{i}.mp4" for i in range(51)]

        response = client.post('/api/vlog/generate', json={
            "user_id": "user_123",
            "template": "travel",
            "clips": clips
        })

        assert response.status_code == 400
        data = response.get_json()
        assert "too many clips" in data["error"]

    def test_database_error_handling(self, client, mock_db, mock_ai_client):
        """
        测试场景：数据库保存失败

        业务链路：
        1. 接收用户请求
        2. 验证参数 ✓
        3. 调用 AI API 成功 ✓
        4. 保存到数据库 → 失败（连接丢失）
        5. 返回 500 错误

        验证重点：
        - 数据库异常处理
        - 返回 500 状态码
        - AI API 仍然被调用（因为在数据库保存之前）
        """
        # Arrange - AI API 成功，数据库保存失败
        mock_ai_instance = mock_ai_client.return_value
        mock_ai_instance.generate_video.return_value = {
            "video_url": "https://cdn.example.com/video123.mp4",
            "duration": 30
        }

        mock_db.session.add = Mock()
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

        # 验证 AI API 被调用
        mock_ai_instance.generate_video.assert_called_once()

        # 验证数据库保存被尝试
        mock_db.session.commit.assert_called_once()

    @pytest.mark.parametrize("template,clips,expected_status", [
        ("travel", ["clip1.mp4"], 200),  # 正常场景
        ("food", ["clip1.mp4", "clip2.mp4"], 200),  # 多个视频片段
        ("daily", ["clip1.mp4"], 200),  # 其他模板
        ("invalid", ["clip1.mp4"], 400),  # 无效模板
        ("travel", [], 400),  # 缺少视频片段
    ])
    def test_vlog_generation_scenarios(self, client, mock_db, mock_ai_client,
                                       template, clips, expected_status):
        """
        参数化测试多种场景

        验证重点：
        - 覆盖多种输入组合
        - 验证不同的业务分支
        """
        if expected_status == 200:
            # 只有成功场景需要 Mock
            mock_ai_instance = mock_ai_client.return_value
            mock_ai_instance.generate_video.return_value = {
                "video_url": "https://cdn.example.com/video123.mp4",
                "duration": 30
            }

            mock_db.session.add = Mock()
            mock_db.session.commit = Mock()

        response = client.post('/api/vlog/generate', json={
            "user_id": "user_123",
            "template": template,
            "clips": clips
        })

        assert response.status_code == expected_status
```

---

## 关键要点

### ✅ 这是大单元测试，因为：

1. **测试粒度**：测试整个 API Endpoint（Controller → Service）
2. **Mock 边界**：只 Mock 数据库和 AI API（系统边界）
3. **验证重点**：验证业务契约（重试逻辑、参数验证、错误处理）
4. **重构友好**：可以自由重构内部实现（拆分函数、优化算法）而不破坏测试

### ❌ 不是小单元测试，因为：

1. **不 Mock 内部逻辑**：参数验证、Prompt 组装、重试逻辑都使用真实代码
2. **不测试实现细节**：不关心函数调用顺序，不验证中间变量
3. **覆盖完整链路**：从 HTTP 请求到数据库保存的整个流程

### 🎯 测试覆盖的业务契约

| 业务契约 | 测试用例 |
|---------|---------|
| 正常流程：生成视频并保存 | `test_successful_vlog_generation` |
| 异常处理：AI API 失败后重试 | `test_retry_on_ai_api_failure` |
| 参数验证：无效模板 | `test_validation_error_on_invalid_template` |
| 参数验证：空视频片段 | `test_validation_error_on_empty_clips` |
| 参数验证：视频片段过多 | `test_validation_error_on_too_many_clips` |
| 异常处理：数据库保存失败 | `test_database_error_handling` |
| 多场景覆盖：参数化测试 | `test_vlog_generation_scenarios` |

---

## 运行测试

```bash
# 运行所有测试
pytest tests/test_vlog_api.py -v

# 运行特定测试
pytest tests/test_vlog_api.py::TestVlogGenerationAPI::test_successful_vlog_generation -v

# 运行并显示覆盖率
pytest tests/test_vlog_api.py --cov=app --cov-report=html

# 运行参数化测试
pytest tests/test_vlog_api.py::TestVlogGenerationAPI::test_vlog_generation_scenarios -v
```

---

**Remember**: 这个测试让你敢于重构 VlogService 的内部实现（如改变重试策略、优化 Prompt 组装），因为只要业务契约不变，测试就会一直通过！⚙️
