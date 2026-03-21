# Go net/http 大单元测试模板

> **适用于**：Go 标准库 `net/http` 的 API Endpoint 测试

## 测试环境配置

### 依赖安装

```bash
go get github.com/stretchr/testify/assert
go get github.com/stretchr/testify/mock
go get github.com/golang/mock/gomock
```

### 项目结构

```
project/
├── handlers/
│   ├── vlog_handler.go
│   └── vlog_handler_test.go
├── services/
│   ├── vlog_service.go
│   └── vlog_service_interface.go
├── mocks/
│   ├── mock_database.go
│   └── mock_ai_client.go
└── testutil/
    └── helpers.go
```

---

## 测试模板

### 基础模板（Table-Driven + httptest）

```go
package handlers_test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/golang/mock/gomock"
	"github.com/stretchr/testify/assert"
	"your_project/handlers"
	"your_project/mocks"
)

func TestVlogGenerationHandler(t *testing.T) {
	tests := []struct {
		name           string
		requestBody    map[string]interface{}
		mockSetup      func(*mocks.MockDatabase, *mocks.MockAIClient)
		expectedStatus int
		expectedBody   map[string]interface{}
	}{
		{
			name: "成功生成 Vlog",
			requestBody: map[string]interface{}{
				"user_id":  "user_123",
				"template": "travel",
				"clips":    []string{"clip1.mp4", "clip2.mp4"},
			},
			mockSetup: func(mockDB *mocks.MockDatabase, mockAI *mocks.MockAIClient) {
				// Mock AI API 调用
				mockAI.EXPECT().
					GenerateVideo(gomock.Any(), "travel", gomock.Any()).
					Return(&AIResponse{
						VideoURL: "https://cdn.example.com/video123.mp4",
						Duration: 30,
					}, nil)

				// Mock 数据库保存
				mockDB.EXPECT().
					SaveVlog(gomock.Any()).
					Return(nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody: map[string]interface{}{
				"video_url": "https://cdn.example.com/video123.mp4",
				"duration":  float64(30),
			},
		},
		{
			name: "无效模板参数",
			requestBody: map[string]interface{}{
				"user_id":  "user_123",
				"template": "invalid_template",
				"clips":    []string{"clip1.mp4"},
			},
			mockSetup: func(mockDB *mocks.MockDatabase, mockAI *mocks.MockAIClient) {
				// 不需要 Mock，因为在参数验证阶段就会返回错误
			},
			expectedStatus: http.StatusBadRequest,
			expectedBody: map[string]interface{}{
				"error": "invalid template",
			},
		},
		{
			name: "AI API 失败后重试",
			requestBody: map[string]interface{}{
				"user_id":  "user_123",
				"template": "travel",
				"clips":    []string{"clip1.mp4"},
			},
			mockSetup: func(mockDB *mocks.MockDatabase, mockAI *mocks.MockAIClient) {
				// Mock AI API 前 2 次失败，第 3 次成功
				gomock.InOrder(
					mockAI.EXPECT().
						GenerateVideo(gomock.Any(), "travel", gomock.Any()).
						Return(nil, errors.New("AI API timeout")),
					mockAI.EXPECT().
						GenerateVideo(gomock.Any(), "travel", gomock.Any()).
						Return(nil, errors.New("AI API rate limit")),
					mockAI.EXPECT().
						GenerateVideo(gomock.Any(), "travel", gomock.Any()).
						Return(&AIResponse{
							VideoURL: "https://cdn.example.com/video123.mp4",
							Duration: 30,
						}, nil),
				)

				// Mock 数据库保存
				mockDB.EXPECT().
					SaveVlog(gomock.Any()).
					Return(nil)
			},
			expectedStatus: http.StatusOK,
			expectedBody: map[string]interface{}{
				"video_url": "https://cdn.example.com/video123.mp4",
			},
		},
		{
			name: "数据库保存失败",
			requestBody: map[string]interface{}{
				"user_id":  "user_123",
				"template": "travel",
				"clips":    []string{"clip1.mp4"},
			},
			mockSetup: func(mockDB *mocks.MockDatabase, mockAI *mocks.MockAIClient) {
				// Mock AI API 成功
				mockAI.EXPECT().
					GenerateVideo(gomock.Any(), "travel", gomock.Any()).
					Return(&AIResponse{
						VideoURL: "https://cdn.example.com/video123.mp4",
						Duration: 30,
					}, nil)

				// Mock 数据库保存失败
				mockDB.EXPECT().
					SaveVlog(gomock.Any()).
					Return(errors.New("database connection lost"))
			},
			expectedStatus: http.StatusInternalServerError,
			expectedBody: map[string]interface{}{
				"error": "failed to save vlog",
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Arrange - 创建 Mock 对象
			ctrl := gomock.NewController(t)
			defer ctrl.Finish()

			mockDB := mocks.NewMockDatabase(ctrl)
			mockAI := mocks.NewMockAIClient(ctrl)

			// 设置 Mock 行为
			tt.mockSetup(mockDB, mockAI)

			// 创建 Handler（注入 Mock 依赖）
			handler := handlers.NewVlogHandler(mockDB, mockAI)

			// 构造 HTTP 请求
			body, _ := json.Marshal(tt.requestBody)
			req := httptest.NewRequest(http.MethodPost, "/api/vlog/generate", bytes.NewBuffer(body))
			req.Header.Set("Content-Type", "application/json")
			w := httptest.NewRecorder()

			// Act - 调用完整的业务链路
			handler.ServeHTTP(w, req)

			// Assert - 验证业务契约
			assert.Equal(t, tt.expectedStatus, w.Code)

			if tt.expectedBody != nil {
				var response map[string]interface{}
				err := json.Unmarshal(w.Body.Bytes(), &response)
				assert.NoError(t, err)

				for key, expectedValue := range tt.expectedBody {
					assert.Equal(t, expectedValue, response[key])
				}
			}
		})
	}
}
```

---

## Mock 策略

### 1. 使用 gomock 生成 Mock

```bash
# 生成 Mock 接口
mockgen -source=services/database_interface.go -destination=mocks/mock_database.go -package=mocks
mockgen -source=services/ai_client_interface.go -destination=mocks/mock_ai_client.go -package=mocks
```

**接口定义**：

```go
// services/database_interface.go
package services

type Database interface {
	SaveVlog(vlog *Vlog) error
	GetVlog(id string) (*Vlog, error)
	DeleteVlog(id string) error
}

// services/ai_client_interface.go
package services

type AIClient interface {
	GenerateVideo(ctx context.Context, template string, clips []string) (*AIResponse, error)
	GetStatus(ctx context.Context, taskID string) (*TaskStatus, error)
}
```

### 2. 手动创建 Mock（小型项目）

```go
// mocks/mock_database.go
package mocks

type MockDatabase struct {
	SaveVlogFunc   func(vlog *Vlog) error
	GetVlogFunc    func(id string) (*Vlog, error)
	DeleteVlogFunc func(id string) error
}

func (m *MockDatabase) SaveVlog(vlog *Vlog) error {
	if m.SaveVlogFunc != nil {
		return m.SaveVlogFunc(vlog)
	}
	return nil
}

func (m *MockDatabase) GetVlog(id string) (*Vlog, error) {
	if m.GetVlogFunc != nil {
		return m.GetVlogFunc(id)
	}
	return nil, nil
}

func (m *MockDatabase) DeleteVlog(id string) error {
	if m.DeleteVlogFunc != nil {
		return m.DeleteVlogFunc(id)
	}
	return nil
}
```

**使用示例**：

```go
func TestWithManualMock(t *testing.T) {
	mockDB := &mocks.MockDatabase{
		SaveVlogFunc: func(vlog *Vlog) error {
			return nil
		},
		GetVlogFunc: func(id string) (*Vlog, error) {
			return &Vlog{ID: id, Title: "Test"}, nil
		},
	}

	handler := handlers.NewVlogHandler(mockDB, nil)
	// ... 测试逻辑
}
```

### 3. Mock HTTP 客户端

```go
// testutil/mock_http.go
package testutil

type RoundTripFunc func(req *http.Request) *http.Response

func (f RoundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req), nil
}

func NewMockHTTPClient(fn RoundTripFunc) *http.Client {
	return &http.Client{
		Transport: fn,
	}
}

// 使用示例
func TestExternalAPI(t *testing.T) {
	mockClient := testutil.NewMockHTTPClient(func(req *http.Request) *http.Response {
		return &http.Response{
			StatusCode: 200,
			Body:       io.NopCloser(strings.NewReader(`{"status": "success"}`)),
			Header:     make(http.Header),
		}
	})

	service := services.NewExternalService(mockClient)
	// ... 测试逻辑
}
```

---

## 高级模式

### 子测试（Subtests）组织

```go
func TestVlogHandler(t *testing.T) {
	// 共享的测试设置
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockDB := mocks.NewMockDatabase(ctrl)
	mockAI := mocks.NewMockAIClient(ctrl)

	t.Run("Create", func(t *testing.T) {
		t.Run("Success", func(t *testing.T) {
			// 测试成功创建
		})

		t.Run("InvalidInput", func(t *testing.T) {
			// 测试无效输入
		})
	})

	t.Run("Get", func(t *testing.T) {
		t.Run("Exists", func(t *testing.T) {
			// 测试获取存在的资源
		})

		t.Run("NotFound", func(t *testing.T) {
			// 测试获取不存在的资源
		})
	})
}
```

### 并发测试

```go
func TestVlogHandlerConcurrency(t *testing.T) {
	handler := setupHandler(t)

	// 模拟并发请求
	var wg sync.WaitGroup
	numRequests := 100

	for i := 0; i < numRequests; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()

			req := httptest.NewRequest(http.MethodGet, fmt.Sprintf("/api/vlog/%d", id), nil)
			w := httptest.NewRecorder()

			handler.ServeHTTP(w, req)

			assert.Equal(t, http.StatusOK, w.Code)
		}(i)
	}

	wg.Wait()
}
```

### 测试辅助函数

```go
// testutil/helpers.go
package testutil

func CreateMockVlogRequest(t *testing.T, template string, clips []string) *http.Request {
	t.Helper()

	body := map[string]interface{}{
		"user_id":  "user_123",
		"template": template,
		"clips":    clips,
	}

	data, err := json.Marshal(body)
	if err != nil {
		t.Fatalf("failed to marshal request body: %v", err)
	}

	req := httptest.NewRequest(http.MethodPost, "/api/vlog/generate", bytes.NewBuffer(data))
	req.Header.Set("Content-Type", "application/json")
	return req
}

func AssertJSONResponse(t *testing.T, w *httptest.ResponseRecorder, expectedStatus int, expectedBody map[string]interface{}) {
	t.Helper()

	assert.Equal(t, expectedStatus, w.Code)

	if expectedBody != nil {
		var response map[string]interface{}
		err := json.Unmarshal(w.Body.Bytes(), &response)
		assert.NoError(t, err)

		for key, expectedValue := range expectedBody {
			assert.Equal(t, expectedValue, response[key])
		}
	}
}
```

---

## 最佳实践

### ✅ DO

1. **使用 Table-Driven Tests** 覆盖多种场景
2. **使用 httptest** 测试 HTTP Handler
3. **使用 gomock** 生成类型安全的 Mock
4. **使用子测试** 组织相关测试
5. **使用 testutil** 提取通用测试逻辑
6. **验证 Mock 调用次数和参数**

### ❌ DON'T

1. **不要 Mock 内部业务逻辑函数**
2. **不要在测试中使用 time.Sleep()**（使用 channel 或 context）
3. **不要忽略 gomock.Controller.Finish()**
4. **不要在测试中使用全局状态**
5. **不要让测试依赖执行顺序**

---

## 运行测试

```bash
# 运行所有测试
go test ./...

# 运行特定包
go test ./handlers

# 运行特定测试
go test -run TestVlogGenerationHandler

# 运行并显示覆盖率
go test -cover ./...

# 生成覆盖率报告
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out

# 运行并行测试
go test -parallel 4 ./...

# 运行竞态检测
go test -race ./...

# 运行基准测试
go test -bench=. ./...
```

---

## 常见问题

### Q: 如何测试需要认证的 Handler？

```go
func TestProtectedHandler(t *testing.T) {
	handler := setupHandler(t)

	req := httptest.NewRequest(http.MethodPost, "/api/vlog/generate", nil)
	req.Header.Set("Authorization", "Bearer test_token_123")
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}
```

### Q: 如何测试 Context 超时？

```go
func TestContextTimeout(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockAI := mocks.NewMockAIClient(ctrl)

	// Mock AI API 慢速响应
	mockAI.EXPECT().
		GenerateVideo(gomock.Any(), gomock.Any(), gomock.Any()).
		DoAndReturn(func(ctx context.Context, template string, clips []string) (*AIResponse, error) {
			select {
			case <-time.After(5 * time.Second):
				return &AIResponse{}, nil
			case <-ctx.Done():
				return nil, ctx.Err()
			}
		})

	handler := handlers.NewVlogHandler(nil, mockAI)

	// 创建带超时的 Context
	ctx, cancel := context.WithTimeout(context.Background(), 1*time.Second)
	defer cancel()

	req := httptest.NewRequest(http.MethodPost, "/api/vlog/generate", nil)
	req = req.WithContext(ctx)
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	assert.Equal(t, http.StatusRequestTimeout, w.Code)
}
```

### Q: 如何测试文件上传？

```go
func TestFileUpload(t *testing.T) {
	// 创建 multipart 表单
	body := &bytes.Buffer{}
	writer := multipart.NewWriter(body)

	part, err := writer.CreateFormFile("file", "test.mp4")
	assert.NoError(t, err)

	_, err = part.Write([]byte("test video content"))
	assert.NoError(t, err)

	err = writer.Close()
	assert.NoError(t, err)

	// 创建请求
	req := httptest.NewRequest(http.MethodPost, "/api/upload", body)
	req.Header.Set("Content-Type", writer.FormDataContentType())
	w := httptest.NewRecorder()

	handler.ServeHTTP(w, req)

	assert.Equal(t, http.StatusOK, w.Code)
}
```

---

**Remember**: 大单元测试关注业务契约，而非实现细节。测试的是"齿轮组"，而非"螺丝钉"。⚙️
