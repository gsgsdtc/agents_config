# Java Spring Boot 大单元测试模板

> **适用于**：Spring Boot 应用的 API Endpoint 测试

## 测试环境配置

### 依赖配置（`pom.xml`）

```xml
<dependencies>
    <!-- Spring Boot Test Starter -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>

    <!-- JUnit 5 -->
    <dependency>
        <groupId>org.junit.jupiter</groupId>
        <artifactId>junit-jupiter</artifactId>
        <scope>test</scope>
    </dependency>

    <!-- Mockito -->
    <dependency>
        <groupId>org.mockito</groupId>
        <artifactId>mockito-core</artifactId>
        <scope>test</scope>
    </dependency>

    <!-- REST Assured (可选，用于 API 测试) -->
    <dependency>
        <groupId>io.rest-assured</groupId>
        <artifactId>rest-assured</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

### 项目结构

```
src/
├── main/java/com/example/
│   ├── controller/
│   │   └── VlogController.java
│   ├── service/
│   │   ├── VlogService.java
│   │   └── AIClient.java
│   ├── repository/
│   │   └── VlogRepository.java
│   └── model/
│       └── Vlog.java
└── test/java/com/example/
    ├── controller/
    │   └── VlogControllerTest.java
    └── testutil/
        └── TestHelpers.java
```

---

## 测试模板

### 基础模板（@WebMvcTest + Mockito）

```java
package com.example.controller;

import com.example.model.Vlog;
import com.example.service.VlogService;
import com.example.service.AIClient;
import com.example.repository.VlogRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@WebMvcTest(VlogController.class)
class VlogControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    // Mock 系统边界
    @MockBean
    private VlogRepository vlogRepository;

    @MockBean
    private AIClient aiClient;

    // 不 Mock 业务逻辑层
    @Autowired
    private VlogService vlogService;

    @BeforeEach
    void setUp() {
        // 测试前置设置（如果需要）
    }

    @Test
    @DisplayName("测试场景：成功生成 Vlog")
    void testSuccessfulVlogGeneration() throws Exception {
        // Arrange（准备）- 设置 Mock 行为
        Map<String, Object> aiResponse = new HashMap<>();
        aiResponse.put("videoUrl", "https://cdn.example.com/video123.mp4");
        aiResponse.put("duration", 30);

        when(aiClient.generateVideo(eq("travel"), anyList()))
                .thenReturn(aiResponse);

        when(vlogRepository.save(any(Vlog.class)))
                .thenAnswer(invocation -> {
                    Vlog vlog = invocation.getArgument(0);
                    vlog.setId(123L);
                    return vlog;
                });

        // 构造请求体
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("userId", "user_123");
        requestBody.put("template", "travel");
        requestBody.put("clips", Arrays.asList("clip1.mp4", "clip2.mp4"));

        // Act（执行）- 调用完整的 API
        mockMvc.perform(post("/api/vlog/generate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                // Assert（断言）- 验证业务契约
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.videoUrl").value("https://cdn.example.com/video123.mp4"))
                .andExpect(jsonPath("$.duration").value(30));

        // 验证副作用：数据库保存
        verify(vlogRepository, times(1)).save(any(Vlog.class));

        // 验证副作用：AI API 调用
        verify(aiClient, times(1)).generateVideo(eq("travel"), anyList());
    }

    @Test
    @DisplayName("测试场景：AI API 失败后重试")
    void testRetryOnAIApiFailure() throws Exception {
        // Arrange - AI API 前 2 次失败，第 3 次成功
        Map<String, Object> successResponse = new HashMap<>();
        successResponse.put("videoUrl", "https://cdn.example.com/video123.mp4");
        successResponse.put("duration", 30);

        when(aiClient.generateVideo(eq("travel"), anyList()))
                .thenThrow(new RuntimeException("AI API timeout"))
                .thenThrow(new RuntimeException("AI API rate limit"))
                .thenReturn(successResponse);

        when(vlogRepository.save(any(Vlog.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("userId", "user_123");
        requestBody.put("template", "travel");
        requestBody.put("clips", Arrays.asList("clip1.mp4"));

        // Act & Assert - 验证重试 3 次
        mockMvc.perform(post("/api/vlog/generate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.videoUrl").value("https://cdn.example.com/video123.mp4"));

        // 验证 AI API 被调用 3 次
        verify(aiClient, times(3)).generateVideo(eq("travel"), anyList());
    }

    @Test
    @DisplayName("测试场景：无效模板参数")
    void testValidationErrorOnInvalidTemplate() throws Exception {
        // Act - 发送无效模板
        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("userId", "user_123");
        requestBody.put("template", "invalid_template");
        requestBody.put("clips", Arrays.asList("clip1.mp4"));

        // Assert
        mockMvc.perform(post("/api/vlog/generate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("invalid template"));

        // 验证不应该调用 AI API 和数据库
        verify(aiClient, never()).generateVideo(anyString(), anyList());
        verify(vlogRepository, never()).save(any(Vlog.class));
    }

    @Test
    @DisplayName("测试场景：数据库保存失败")
    void testDatabaseErrorHandling() throws Exception {
        // Arrange - AI API 成功，数据库保存失败
        Map<String, Object> aiResponse = new HashMap<>();
        aiResponse.put("videoUrl", "https://cdn.example.com/video123.mp4");
        aiResponse.put("duration", 30);

        when(aiClient.generateVideo(anyString(), anyList()))
                .thenReturn(aiResponse);

        when(vlogRepository.save(any(Vlog.class)))
                .thenThrow(new RuntimeException("Database connection lost"));

        Map<String, Object> requestBody = new HashMap<>();
        requestBody.put("userId", "user_123");
        requestBody.put("template", "travel");
        requestBody.put("clips", Arrays.asList("clip1.mp4"));

        // Act & Assert
        mockMvc.perform(post("/api/vlog/generate")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.error").exists());

        // 验证 AI API 被调用
        verify(aiClient, times(1)).generateVideo(anyString(), anyList());

        // 验证数据库保存被尝试
        verify(vlogRepository, times(1)).save(any(Vlog.class));
    }
}
```

---

## Mock 策略

### 1. @MockBean vs @Mock

```java
// @MockBean - Spring 管理的 Mock（推荐用于 @WebMvcTest）
@MockBean
private VlogRepository vlogRepository;

// @Mock - 纯 Mockito Mock（用于单元测试）
@ExtendWith(MockitoExtension.class)
class VlogServiceTest {
    @Mock
    private VlogRepository vlogRepository;

    @InjectMocks
    private VlogService vlogService;
}
```

### 2. Mock JPA Repository

```java
@MockBean
private VlogRepository vlogRepository;

@Test
void testFindById() {
    Vlog mockVlog = new Vlog();
    mockVlog.setId(123L);
    mockVlog.setTitle("Test Vlog");

    when(vlogRepository.findById(123L))
            .thenReturn(Optional.of(mockVlog));

    // 测试逻辑...
}
```

### 3. Mock REST Template / WebClient

```java
@MockBean
private RestTemplate restTemplate;

@Test
void testExternalAPICall() {
    ResponseEntity<Map<String, Object>> mockResponse =
            ResponseEntity.ok(Map.of("status", "success"));

    when(restTemplate.postForEntity(
            anyString(),
            any(HttpEntity.class),
            eq(new ParameterizedTypeReference<Map<String, Object>>() {})
    )).thenReturn(mockResponse);

    // 测试逻辑...
}
```

---

## 高级模式

### 参数化测试（@ParameterizedTest）

```java
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.MethodSource;

import java.util.stream.Stream;

@ParameterizedTest
@CsvSource({
    "travel, clip1.mp4, 200",
    "food, clip1.mp4, 200",
    "invalid, clip1.mp4, 400",
    "travel, '', 400"
})
@DisplayName("参数化测试多种场景")
void testVlogGenerationScenarios(String template, String clip, int expectedStatus) throws Exception {
    // 测试逻辑...
}

@ParameterizedTest
@MethodSource("provideTestCases")
@DisplayName("复杂参数化测试")
void testWithMethodSource(VlogRequest request, int expectedStatus) throws Exception {
    // 测试逻辑...
}

static Stream<Arguments> provideTestCases() {
    return Stream.of(
        Arguments.of(new VlogRequest("user1", "travel", Arrays.asList("clip1.mp4")), 200),
        Arguments.of(new VlogRequest("user2", "food", Arrays.asList("clip1.mp4", "clip2.mp4")), 200),
        Arguments.of(new VlogRequest("user3", "invalid", Arrays.asList("clip1.mp4")), 400)
    );
}
```

### 测试辅助类

```java
// testutil/TestHelpers.java
package com.example.testutil;

public class TestHelpers {
    public static Vlog createMockVlog(Long id, String title, String userId) {
        Vlog vlog = new Vlog();
        vlog.setId(id);
        vlog.setTitle(title);
        vlog.setUserId(userId);
        vlog.setCreatedAt(LocalDateTime.now());
        return vlog;
    }

    public static Map<String, Object> createVlogRequest(String userId, String template, List<String> clips) {
        Map<String, Object> request = new HashMap<>();
        request.put("userId", userId);
        request.put("template", template);
        request.put("clips", clips);
        return request;
    }

    public static void assertVlogResponse(ResultActions resultActions, String expectedVideoUrl, int expectedDuration) throws Exception {
        resultActions
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.videoUrl").value(expectedVideoUrl))
            .andExpect(jsonPath("$.duration").value(expectedDuration));
    }
}
```

### 异步操作测试

```java
import org.springframework.scheduling.annotation.Async;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import java.util.concurrent.CompletableFuture;

@Test
@DisplayName("测试异步 Vlog 生成")
void testAsyncVlogGeneration() throws Exception {
    CompletableFuture<Map<String, Object>> futureResponse =
            CompletableFuture.completedFuture(Map.of("videoUrl", "https://example.com/video.mp4"));

    when(aiClient.generateVideoAsync(anyString(), anyList()))
            .thenReturn(futureResponse);

    mockMvc.perform(post("/api/vlog/generate_async")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(requestBody)))
            .andExpect(status().isAccepted())
            .andExpect(jsonPath("$.taskId").exists());
}
```

---

## 最佳实践

### ✅ DO

1. **使用 @WebMvcTest** 测试 Controller 层
2. **使用 @MockBean** Mock 系统边界
3. **使用 MockMvc** 模拟 HTTP 请求
4. **使用 @DisplayName** 提供清晰的测试说明
5. **使用 @ParameterizedTest** 覆盖多种场景
6. **使用 ObjectMapper** 序列化/反序列化 JSON

### ❌ DON'T

1. **不要 Mock Service 层的业务逻辑**
2. **不要使用 @SpringBootTest** 做大单元测试（太慢）
3. **不要在测试中使用真实数据库**
4. **不要忽略异常处理测试**
5. **不要让测试依赖执行顺序**

---

## 运行测试

```bash
# Maven
mvn test

# 运行特定测试类
mvn test -Dtest=VlogControllerTest

# 运行特定测试方法
mvn test -Dtest=VlogControllerTest#testSuccessfulVlogGeneration

# 运行并生成覆盖率报告
mvn test jacoco:report

# Gradle
./gradlew test

# 运行特定测试
./gradlew test --tests VlogControllerTest

# 运行并生成覆盖率
./gradlew test jacocoTestReport
```

---

## 常见问题

### Q: 如何测试需要认证的 API？

```java
@Test
@DisplayName("测试需要认证的 API")
@WithMockUser(username = "user123", roles = {"USER"})
void testProtectedEndpoint() throws Exception {
    mockMvc.perform(post("/api/vlog/generate")
                    .header("Authorization", "Bearer test_token")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(requestBody)))
            .andExpect(status().isOk());
}
```

### Q: 如何测试文件上传？

```java
@Test
@DisplayName("测试文件上传")
void testFileUpload() throws Exception {
    MockMultipartFile file = new MockMultipartFile(
            "file",
            "test.mp4",
            MediaType.APPLICATION_OCTET_STREAM_VALUE,
            "test video content".getBytes()
    );

    mockMvc.perform(multipart("/api/upload")
                    .file(file)
                    .param("userId", "user123"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.fileUrl").exists());

    verify(storageService, times(1)).uploadFile(any(MultipartFile.class));
}
```

### Q: 如何测试事务？

```java
@Test
@DisplayName("测试事务回滚")
void testTransactionRollback() throws Exception {
    when(vlogRepository.save(any(Vlog.class)))
            .thenThrow(new DataIntegrityViolationException("Constraint violation"));

    mockMvc.perform(post("/api/vlog/generate")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(requestBody)))
            .andExpect(status().isInternalServerError());

    // 验证事务回滚（如果有其他操作应该被回滚）
    verify(notificationService, never()).sendNotification(anyString());
}
```

---

**Remember**: 大单元测试关注业务契约，而非实现细节。测试的是"齿轮组"，而非"螺丝钉"。⚙️
