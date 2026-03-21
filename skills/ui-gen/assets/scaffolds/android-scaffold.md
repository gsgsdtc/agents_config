# Android 项目骨架模板 (Jetpack Compose + MVVM)

> 此模板由 ui-gen Phase 0 使用，为已有的 Android Studio 项目注入 MVVM 架构骨架。
> 技术栈：Jetpack Compose + Material 3 + Navigation Compose + Kotlin Coroutines
> 前置条件：用户已通过 Android Studio 创建了基础 Compose 项目（Empty Compose Activity 模板）

---

## 1. 前置条件

| 项目 | 最低要求 | 推荐版本 |
|------|---------|---------|
| Android Studio | Hedgehog (2023.1.1) | Ladybug (2024.2.1)+ |
| AGP | 8.1+ | 8.7+ |
| Kotlin | 1.9+ | 2.0+ |
| minSdk | 26 | 28 |
| targetSdk | 34+ | 35 |
| compileSdk | 34+ | 35 |

**确认清单**（执行 Phase 0 前必须满足）：

- [ ] 用户已通过 Android Studio 创建了 Empty Compose Activity 项目
- [ ] 项目可正常编译并运行（默认 Greeting 界面可显示）
- [ ] 确认项目包名（如 `com.example.myapp`），后续目录结构基于此包名

---

## 2. 注入目录结构

在主源码集 `app/src/main/java/{包路径}/` 下注入以下结构：

```
app/src/main/java/com/example/{projectname}/
├── ui/
│   ├── navigation/
│   │   ├── AppNavigation.kt          # 导航壳（NavHost + 路由定义）
│   │   └── Routes.kt                 # 路由 sealed interface + @Serializable 定义
│   ├── screens/                       # 按功能模块组织的屏幕（Phase 1/2 生成，此处仅占位）
│   │   └── placeholder/
│   │       └── PlaceholderScreen.kt   # 占位屏幕 Composable
│   ├── components/                    # 可复用 Composable 组件
│   │   ├── EmptyState.kt             # 空状态组件
│   │   ├── ErrorState.kt             # 错误状态组件
│   │   └── LoadingShimmer.kt         # 骨架屏 Shimmer 组件
│   └── theme/                         # Material 3 主题（通常由 Android Studio 生成，无需覆盖）
├── data/
│   ├── remote/
│   │   ├── ApiClient.kt              # 网络客户端（OkHttp + kotlinx.serialization）
│   │   ├── ApiResult.kt              # 统一网络响应封装
│   │   └── TokenInterceptor.kt       # Token 拦截器
│   └── repository/                    # Repository 层
│       └── BaseRepository.kt         # Repository 基类 / 示例接口
├── model/                             # 数据模型 (data class)
│   └── .gitkeep                       # Phase 1/2 生成具体模型
├── viewmodel/                         # ViewModel (StateFlow)
│   └── .gitkeep                       # Phase 1/2 生成具体 ViewModel
└── utils/                             # 工具类
    └── .gitkeep
```

**注意**：`ui/theme/` 目录在创建 Compose 项目时已由 Android Studio 生成（包含 `Color.kt`、`Theme.kt`、`Type.kt`），Phase 0 不覆盖此目录。

---

## 3. 基础文件生成规则

### 3.1 导航壳选择

在执行 Phase 0 前，询问用户选择导航模式：

| 用户选择 | 对应 Layout Pattern | 生成内容 |
|---------|---------------------|---------|
| BottomNav + NavHost | `references/android/layout-patterns.md` Pattern 1 | `AppNavigation.kt` = Scaffold + NavigationBar + NavHost |
| NavigationDrawer | `references/android/layout-patterns.md` Pattern 2 | `AppNavigation.kt` = ModalNavigationDrawer + TopAppBar + NavHost |
| 全屏布局（无导航壳） | `references/android/layout-patterns.md` Pattern 3 | `AppNavigation.kt` = 纯 NavHost，无 Scaffold 包裹 |

**默认选择**：BottomNav + NavHost（主流 Android 消费类应用）

### 3.2 路由定义 (Routes.kt)

独立路由文件，所有路由使用 type-safe navigation（`@Serializable` data object）。

```kotlin
// ui/navigation/Routes.kt

package {包名}.ui.navigation

import kotlinx.serialization.Serializable

/**
 * 顶级路由定义。
 * Phase 1/2 生成业务屏幕后，在此追加新路由。
 */
sealed interface AppRoute {

    @Serializable
    data object Home : AppRoute

    @Serializable
    data object Settings : AppRoute

    // Phase 1/2 追加业务路由示例：
    // @Serializable
    // data object UserList : AppRoute
    //
    // @Serializable
    // data class UserDetail(val userId: String) : AppRoute
}
```

### 3.3 导航壳 (AppNavigation.kt)

根据用户选择的导航模式，从 `references/android/layout-patterns.md` 提取对应代码片段并适配。

**BottomNav 模式（默认）关键要素**：

```kotlin
// ui/navigation/AppNavigation.kt

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val navBackStackEntry by navController.currentBackStackEntryAsState()
    val currentDestination = navBackStackEntry?.destination

    Scaffold(
        bottomBar = {
            NavigationBar {
                topLevelRoutes.forEach { route ->
                    val selected = currentDestination?.hierarchy?.any {
                        it.hasRoute(route.destination::class)
                    } == true

                    NavigationBarItem(
                        selected = selected,
                        onClick = {
                            navController.navigate(route.destination) {
                                popUpTo(navController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        },
                        icon = { /* selected / unselected icon */ },
                        label = { Text(route.label) },
                    )
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = AppRoute.Home,
            modifier = Modifier.padding(innerPadding),
        ) {
            composable<AppRoute.Home> { PlaceholderScreen("首页") }
            composable<AppRoute.Settings> { PlaceholderScreen("设置") }
        }
    }
}
```

**NavigationDrawer 模式关键要素**：

```kotlin
// ui/navigation/AppNavigation.kt

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val scope = rememberCoroutineScope()

    ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet {
                Text(
                    text = "应用名称",
                    style = MaterialTheme.typography.titleLarge,
                    modifier = Modifier.padding(horizontal = 28.dp, vertical = 24.dp),
                )
                HorizontalDivider()
                // NavigationDrawerItem 列表...
            }
        },
    ) {
        Scaffold(
            topBar = {
                TopAppBar(
                    title = { Text("当前页面标题") },
                    navigationIcon = {
                        IconButton(onClick = { scope.launch { drawerState.open() } }) {
                            Icon(Icons.Default.Menu, contentDescription = "打开菜单")
                        }
                    },
                )
            },
        ) { innerPadding ->
            NavHost(
                navController = navController,
                startDestination = AppRoute.Home,
                modifier = Modifier.padding(innerPadding),
            ) {
                composable<AppRoute.Home> { PlaceholderScreen("首页") }
                composable<AppRoute.Settings> { PlaceholderScreen("设置") }
            }
        }
    }
}
```

**全屏布局模式关键要素**：

```kotlin
// ui/navigation/AppNavigation.kt

@Composable
fun AppNavigation() {
    val navController = rememberNavController()

    NavHost(
        navController = navController,
        startDestination = AppRoute.Home,
    ) {
        composable<AppRoute.Home> { PlaceholderScreen("首页") }
        composable<AppRoute.Settings> { PlaceholderScreen("设置") }
    }
}
```

### 3.4 占位屏幕 (PlaceholderScreen.kt)

Phase 0 为每个导航目的地生成一个最简占位 Composable，Phase 1/2 替换为真实业务屏幕。

```kotlin
// ui/screens/placeholder/PlaceholderScreen.kt

package {包名}.ui.screens.placeholder

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier

@Composable
fun PlaceholderScreen(
    title: String,
    modifier: Modifier = Modifier,
) {
    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.headlineMedium,
        )
    }
}
```

### 3.5 通用状态组件

Phase 0 生成三个通用状态 Composable，供后续所有业务屏幕复用。
实现参考 `references/android/layout-patterns.md` 中 Pattern 6（空状态）和 Pattern 7（错误状态）。

**EmptyState.kt**：

```kotlin
// ui/components/EmptyState.kt
// 空数据状态：居中图标 + 描述文案 + 可选操作按钮
// 遵循设计规则 SE1：图标 + 描述文案 + CTA 按钮

@Composable
fun EmptyState(
    icon: ImageVector = Icons.Outlined.Inbox,
    title: String = "暂无数据",
    description: String = "还没有任何记录",
    actionLabel: String? = null,
    onAction: (() -> Unit)? = null,
    modifier: Modifier = Modifier,
)
```

**ErrorState.kt**：

```kotlin
// ui/components/ErrorState.kt
// 请求失败状态：错误图标 + 错误描述 + 重试按钮
// 遵循设计规则 SE2：错误描述 + 重试按钮

@Composable
fun ErrorState(
    message: String = "加载数据时发生错误，请重试",
    onRetry: () -> Unit,
    modifier: Modifier = Modifier,
)
```

**LoadingShimmer.kt**：

```kotlin
// ui/components/LoadingShimmer.kt
// 骨架屏 Shimmer 效果，用于数据加载中状态
// 遵循设计规则 DL1：首次加载用骨架屏，不用 Spinner

@Composable
fun ShimmerBox(
    modifier: Modifier = Modifier,
) {
    val transition = rememberInfiniteTransition(label = "shimmer")
    val translateAnim by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1200, easing = LinearEasing),
            repeatMode = RepeatMode.Restart,
        ),
        label = "shimmerTranslate",
    )
    // Brush.linearGradient + surfaceVariant 颜色
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(4.dp))
            .background(brush),
    )
}

@Composable
fun ShimmerListItem(
    modifier: Modifier = Modifier,
) {
    // 模拟一行列表项的骨架：头像 + 两行文本
    Row(modifier = modifier.padding(16.dp)) {
        ShimmerBox(modifier = Modifier.size(48.dp).clip(CircleShape))
        Spacer(modifier = Modifier.width(16.dp))
        Column(modifier = Modifier.weight(1f)) {
            ShimmerBox(modifier = Modifier.fillMaxWidth(0.7f).height(16.dp))
            Spacer(modifier = Modifier.height(8.dp))
            ShimmerBox(modifier = Modifier.fillMaxWidth(0.5f).height(12.dp))
        }
    }
}
```

### 3.6 网络层 (data/remote/)

Phase 0 生成最小化网络基础设施。默认使用 OkHttp + kotlinx.serialization（减少依赖），如用户偏好 Retrofit 则替换。

**ApiResult.kt** -- 统一网络响应封装：

```kotlin
// data/remote/ApiResult.kt

package {包名}.data.remote

/**
 * 统一网络响应封装，所有 Repository 方法返回此类型。
 */
sealed interface ApiResult<out T> {
    data class Success<T>(val data: T) : ApiResult<T>
    data class Error(val exception: ApiException) : ApiResult<Nothing>
    data object Loading : ApiResult<Nothing>
}

sealed class ApiException(
    override val message: String,
    override val cause: Throwable? = null,
) : Exception(message, cause) {
    class Network(cause: Throwable) : ApiException("网络连接失败", cause)
    class Server(val code: Int, message: String) : ApiException(message)
    class Auth(message: String = "登录已过期，请重新登录") : ApiException(message)
    class Unknown(cause: Throwable) : ApiException("未知错误", cause)
}

/**
 * 便捷扩展：在 ViewModel 中处理 ApiResult。
 */
inline fun <T> ApiResult<T>.onSuccess(action: (T) -> Unit): ApiResult<T> {
    if (this is ApiResult.Success) action(data)
    return this
}

inline fun <T> ApiResult<T>.onError(action: (ApiException) -> Unit): ApiResult<T> {
    if (this is ApiResult.Error) action(exception)
    return this
}
```

**TokenInterceptor.kt** -- Token 拦截器：

```kotlin
// data/remote/TokenInterceptor.kt

package {包名}.data.remote

import okhttp3.Interceptor
import okhttp3.Response

/**
 * OkHttp 拦截器，自动为请求添加 Authorization header。
 * Token 获取逻辑由具体项目实现（SharedPreferences / DataStore / 内存缓存）。
 */
class TokenInterceptor(
    private val getToken: () -> String?,
) : Interceptor {
    override fun intercept(chain: Interceptor.Chain): Response {
        val original = chain.request()
        val token = getToken()
        val request = if (token != null) {
            original.newBuilder()
                .header("Authorization", "Bearer $token")
                .build()
        } else {
            original
        }
        return chain.proceed(request)
    }
}
```

**ApiClient.kt** -- 网络客户端：

```kotlin
// data/remote/ApiClient.kt

package {包名}.data.remote

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * 最小化网络客户端。
 *
 * 使用方式：
 *   val client = ApiClient(baseUrl = "https://api.example.com")
 *   val users: List<User> = client.get("/users")
 */
class ApiClient(
    private val baseUrl: String,
    getToken: () -> String? = { null },
) {
    private val json = Json {
        ignoreUnknownKeys = true
        coerceInputValues = true
        encodeDefaults = true
    }

    private val httpClient = OkHttpClient.Builder()
        .addInterceptor(TokenInterceptor(getToken))
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    /**
     * GET 请求。
     * @param path API 路径（如 "/users"）
     * @param queryParams 查询参数
     */
    suspend inline fun <reified T> get(
        path: String,
        queryParams: Map<String, String> = emptyMap(),
    ): ApiResult<T> = request {
        val urlBuilder = StringBuilder("$baseUrl$path")
        if (queryParams.isNotEmpty()) {
            urlBuilder.append("?")
            urlBuilder.append(queryParams.entries.joinToString("&") { "${it.key}=${it.value}" })
        }
        Request.Builder().url(urlBuilder.toString()).get().build()
    }

    /**
     * POST 请求。
     * @param path API 路径
     * @param body 请求体（会被序列化为 JSON）
     */
    suspend inline fun <reified T, reified B> post(
        path: String,
        body: B,
    ): ApiResult<T> = request {
        val jsonBody = json.encodeToString(body)
        Request.Builder()
            .url("$baseUrl$path")
            .post(jsonBody.toRequestBody("application/json".toMediaType()))
            .build()
    }

    /**
     * 通用请求执行。
     */
    suspend inline fun <reified T> request(
        crossinline buildRequest: () -> Request,
    ): ApiResult<T> = withContext(Dispatchers.IO) {
        try {
            val response = httpClient.newCall(buildRequest()).execute()
            val responseBody = response.body?.string()

            when {
                response.isSuccessful && responseBody != null -> {
                    val data = json.decodeFromString<T>(responseBody)
                    ApiResult.Success(data)
                }
                response.code == 401 -> {
                    ApiResult.Error(ApiException.Auth())
                }
                else -> {
                    ApiResult.Error(
                        ApiException.Server(response.code, responseBody ?: "服务器错误")
                    )
                }
            }
        } catch (e: IOException) {
            ApiResult.Error(ApiException.Network(e))
        } catch (e: Exception) {
            ApiResult.Error(ApiException.Unknown(e))
        }
    }
}
```

### 3.7 Repository 模式占位 (data/repository/)

提供 Repository 基础模式，供 Phase 1/2 参考和继承。

```kotlin
// data/repository/BaseRepository.kt

package {包名}.data.repository

import {包名}.data.remote.ApiClient

/**
 * Repository 基类，持有 ApiClient 引用。
 * 具体 Repository 继承此类并实现业务方法。
 *
 * 示例用法（Phase 1/2 生成）：
 *
 *   class UserRepository(apiClient: ApiClient) : BaseRepository(apiClient) {
 *       suspend fun getUsers(): ApiResult<List<User>> = apiClient.get("/users")
 *       suspend fun getUser(id: String): ApiResult<User> = apiClient.get("/users/$id")
 *   }
 */
abstract class BaseRepository(
    protected val apiClient: ApiClient,
)
```

### 3.8 MainActivity 更新

Phase 0 完成后，提示用户将 `MainActivity.kt` 中的 `setContent {}` 调用替换为新的 `AppNavigation()` 入口。

**替换前（Android Studio 默认）**：

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MyAppTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    Greeting(
                        name = "Android",
                        modifier = Modifier.padding(innerPadding)
                    )
                }
            }
        }
    }
}
```

**替换后**：

```kotlin
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            MyAppTheme {
                AppNavigation()
            }
        }
    }
}
```

**需要添加的 import**：

```kotlin
import {包名}.ui.navigation.AppNavigation
import androidx.activity.enableEdgeToEdge
```

---

## 4. 依赖配置

### 4.1 build.gradle.kts (Module: app) -- plugins 块

```kotlin
plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    // 新增：Kotlin Serialization（type-safe navigation 必需）
    kotlin("plugin.serialization") version "2.0.0"
}
```

> 如果项目使用 Version Catalog（`libs.versions.toml`），在 `[plugins]` 中添加：
> ```toml
> kotlinx-serialization = { id = "org.jetbrains.kotlin.plugin.serialization", version.ref = "kotlin" }
> ```

### 4.2 build.gradle.kts (Module: app) -- dependencies 块

```kotlin
dependencies {
    // ── Compose BOM（统一版本管理） ──
    val composeBom = platform("androidx.compose:compose-bom:2024.12.01")
    implementation(composeBom)
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    implementation("androidx.compose.ui:ui-tooling-preview")
    debugImplementation("androidx.compose.ui:ui-tooling")

    // ── Navigation Compose ──
    implementation("androidx.navigation:navigation-compose:2.8.5")

    // ── Lifecycle + ViewModel ──
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.7")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.8.7")

    // ── Kotlin Serialization（type-safe navigation + JSON 解析） ──
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")

    // ── Kotlin Coroutines ──
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")

    // ── OkHttp（网络请求） ──
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("com.squareup.okhttp3:logging-interceptor:4.12.0")

    // ── Coil（图片加载，可选） ──
    implementation("io.coil-kt:coil-compose:2.7.0")
}
```

### 4.3 依赖用途说明

| 依赖 | 用途 | 必需 |
|------|------|------|
| compose-bom | Compose 版本统一管理 | 是 |
| material3 | Material 3 组件库 | 是 |
| material-icons-extended | 完整图标集（900+） | 是 |
| navigation-compose | Navigation Compose（NavHost + type-safe routes） | 是 |
| lifecycle-viewmodel-compose | `viewModel()` 在 Composable 中获取 ViewModel | 是 |
| lifecycle-runtime-compose | `collectAsStateWithLifecycle()` 安全收集 Flow | 是 |
| kotlinx-serialization-json | JSON 序列化 + type-safe navigation 路由序列化 | 是 |
| kotlinx-coroutines-android | Kotlin 协程 Android 调度器 | 是 |
| okhttp | HTTP 客户端 | 是 |
| logging-interceptor | OkHttp 日志拦截器（debug 用） | 否 |
| coil-compose | 网络图片加载 | 否 |

---

## 5. 用户操作指引

Phase 0 完成后，向用户输出以下操作步骤：

```
## Phase 0 完成 -- 操作指引

### 步骤 1: 添加依赖

1. 打开 `build.gradle.kts (Module: app)`
2. 在 `plugins {}` 块添加 serialization 插件
3. 在 `dependencies {}` 块添加上述依赖
4. 点击 "Sync Now" 同步项目

### 步骤 2: 复制生成文件

将以下文件复制到项目对应包目录下：
- ui/navigation/Routes.kt
- ui/navigation/AppNavigation.kt
- ui/screens/placeholder/PlaceholderScreen.kt
- ui/components/EmptyState.kt
- ui/components/ErrorState.kt
- ui/components/LoadingShimmer.kt
- data/remote/ApiResult.kt
- data/remote/TokenInterceptor.kt
- data/remote/ApiClient.kt
- data/repository/BaseRepository.kt

### 步骤 3: 更新 MainActivity

将 MainActivity.kt 的 setContent {} 中的内容替换为 AppNavigation()

### 步骤 4: 验证

1. 编译项目（Build > Rebuild Project）
2. 运行应用，确认导航壳正常显示
3. 点击底部导航栏 / 抽屉菜单各项，确认切换正常

### 下一步

项目骨架就绪，可以进入 Phase 1（UI Spec 生成）：
- 为每个业务屏幕编写 UI Spec（使用 android 模板）
- 然后执行 Phase 2 生成具体业务屏幕代码
```

---

## 6. 不生成的内容

以下内容由 Phase 1/2 根据 UI Spec 生成，Phase 0 不涉及：

| 内容 | 负责阶段 | 说明 |
|------|---------|------|
| 具体业务屏幕 | Phase 1/2 | 如 UserListScreen、OrderDetailScreen |
| 数据模型 (data class) | Phase 1/2 | 如 User、Order 等业务实体 |
| 具体 API 接口实现 | Phase 1/2 | 如 UserRepository.getUsers() |
| ViewModel 业务逻辑 | Phase 1/2 | 如 UserListViewModel 的状态管理 |
| 表单验证逻辑 | Phase 1/2 | 如邮箱格式校验、必填项检查 |
| 图表/可视化组件 | Phase 1/2 | 如仪表盘中的 Vico 图表 |
| 依赖注入 (DI) | 按需添加 | Hilt / Koin / 手动注入，Phase 0 不预设 |
| 数据持久化 | 按需添加 | Room / DataStore / SharedPreferences |
| 推送通知 | 按需添加 | FCM 配置 |
| 国际化（i18n） | 按需添加 | strings.xml 多语言资源 |
| CI/CD 配置 | 按需添加 | GitHub Actions / Fastlane 等 |

---

## 7. 设计规则遵循

Phase 0 生成的代码必须遵循 `references/design-rules.md` 中的以下规则：

| 规则编号 | 规则内容 | Phase 0 体现 |
|----------|---------|-------------|
| C1 | 只用设计系统语义色 | 所有组件使用 `MaterialTheme.colorScheme.*` |
| A1 | 语义化结构 | Scaffold + NavHost 语义正确 |
| A4 | 纯图标按钮加无障碍标签 | 所有 Icon 提供 `contentDescription` |
| SE1 | 空数据包含图标+描述+CTA | EmptyState 组件实现 |
| SE2 | 请求失败包含错误描述+重试 | ErrorState 组件实现 |
| DL1 | 首次加载用骨架屏 | LoadingShimmer 组件实现 |
| L1 | 间距基于 4px 倍数 | 所有 padding/spacing 使用 8.dp / 16.dp / 24.dp |
