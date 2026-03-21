# iOS 项目骨架模板 (SwiftUI + MVVM)

> 此模板由 ui-gen Phase 0 使用，为已有的 Xcode 项目注入 MVVM 架构骨架。
> 技术栈：SwiftUI (iOS 17+), @Observable, async/await
> 前置条件：用户已通过 Xcode 创建了基础 SwiftUI 项目

---

## 1. 前置条件

| 条件 | 要求 |
|------|------|
| Xcode | 15+ (含 iOS 17 SDK) |
| 部署目标 | iOS 17.0+ |
| 项目状态 | 用户已通过 Xcode 创建空的 SwiftUI App 项目 |
| 已有文件 | `{ProjectName}App.swift`（App 入口）和默认 `ContentView.swift` |

**检测方式**：在项目目录中查找 `.xcodeproj` 或 `Package.swift`，读取 `{ProjectName}App.swift` 确认项目名。

---

## 2. 注入目录结构

在项目 `{ProjectName}/` 源码目录下创建以下文件夹结构：

```
{ProjectName}/
├── App/
│   └── ContentView.swift          # 替换默认 ContentView（导航壳）
├── Models/                        # 数据模型 (struct, Codable, Identifiable)
│   └── .gitkeep
├── ViewModels/                    # ViewModel (@Observable class)
│   └── .gitkeep
├── Views/
│   ├── Components/                # 可复用子视图（按钮、卡片、空状态等）
│   └── Screens/                   # 按功能模块组织的屏幕（Phase 1/2 生成）
│       └── .gitkeep
├── Services/
│   ├── APIClient.swift            # 网络请求客户端
│   └── AuthService.swift          # 认证服务（占位）
├── Utils/
│   └── Extensions.swift           # 常用扩展
└── Resources/                     # 资源文件（颜色集、本地化等）
    └── .gitkeep
```

**注意**：
- 空目录放置 `.gitkeep` 以便 Git 追踪
- `Views/Screens/` 由 Phase 1/2 生成业务屏幕，Phase 0 不填充
- `Models/` 和 `ViewModels/` 由 Phase 1/2 按需求生成

---

## 3. 基础文件生成规则

### 3.1 导航壳选择

根据用户选择的页面级布局，从 `references/ios/layout-patterns.md` 提取对应代码注入 `App/ContentView.swift`。

| 用户选择 | 对应 Pattern | 生成说明 |
|---------|-------------|---------|
| TabBar + NavigationStack | Pattern 1（layout-patterns.md 第 1 节） | AppTab enum + TabView，每个 Tab 包裹 NavigationStack，使用 iOS 17 Tab 初始化语法 |
| Sidebar + NavigationSplitView | Pattern 2（layout-patterns.md 第 2 节） | SidebarItem enum + NavigationSplitView，左侧 List + 右侧 detail 路由 |
| 全屏布局 | Pattern 3（layout-patterns.md 第 3 节） | 无导航壳，GeometryReader + ScrollView 居中布局 |

**默认选择**：TabBar + NavigationStack（主流 iOS 应用模式）

**交互流程**：

```
询问用户 → "请选择导航模式：
  1. TabBar + NavigationStack（默认，适合多功能 App）
  2. Sidebar + NavigationSplitView（适合 iPad/Mac 管理后台）
  3. 全屏布局（适合登录页、引导页等单屏应用）"
→ 用户选择（或使用默认）
→ 从 layout-patterns.md 取代码
→ 根据项目名替换占位视图名
→ 写入 App/ContentView.swift
```

### 3.2 ContentView.swift 生成规则

#### TabBar + NavigationStack（默认）

```swift
// App/ContentView.swift
import SwiftUI

/// 应用主标签页枚举
/// Phase 1/2 生成业务屏幕后，将占位视图替换为实际视图
enum AppTab: String, CaseIterable {
    case home, explore, profile

    var title: String {
        switch self {
        case .home: "首页"
        case .explore: "发现"
        case .profile: "我的"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .explore: "safari"
        case .profile: "person.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(AppTab.home.title, systemImage: AppTab.home.icon, value: .home) {
                NavigationStack {
                    HomePlaceholderView()
                        .navigationTitle(AppTab.home.title)
                }
            }

            Tab(AppTab.explore.title, systemImage: AppTab.explore.icon, value: .explore) {
                NavigationStack {
                    ExplorePlaceholderView()
                        .navigationTitle(AppTab.explore.title)
                }
            }

            Tab(AppTab.profile.title, systemImage: AppTab.profile.icon, value: .profile) {
                NavigationStack {
                    ProfilePlaceholderView()
                        .navigationTitle(AppTab.profile.title)
                }
            }
        }
    }
}

// MARK: - 占位视图（Phase 1/2 替换为实际业务屏幕）

struct HomePlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "首页",
            systemImage: "house",
            description: Text("业务屏幕将在 Phase 1/2 生成")
        )
    }
}

struct ExplorePlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "发现",
            systemImage: "safari",
            description: Text("业务屏幕将在 Phase 1/2 生成")
        )
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "我的",
            systemImage: "person",
            description: Text("业务屏幕将在 Phase 1/2 生成")
        )
    }
}

#Preview {
    ContentView()
}
```

#### Sidebar + NavigationSplitView

```swift
// App/ContentView.swift
import SwiftUI

/// 侧边栏导航项枚举
/// Phase 1/2 生成业务屏幕后，将占位视图替换为实际视图
enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard, settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "概览"
        case .settings: "设置"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .settings: "gearshape"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: SidebarItem? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(SidebarItem.allCases, selection: $selectedItem) { item in
                Label(item.title, systemImage: item.icon)
                    .tag(item)
            }
            .navigationTitle("管理后台")
        } detail: {
            if let selectedItem {
                switch selectedItem {
                case .dashboard:
                    DashboardPlaceholderView()
                case .settings:
                    SettingsPlaceholderView()
                }
            } else {
                ContentUnavailableView(
                    "请选择一个模块",
                    systemImage: "sidebar.left",
                    description: Text("从左侧边栏选择一个功能模块开始使用")
                )
            }
        }
    }
}

// MARK: - 占位视图（Phase 1/2 替换为实际业务屏幕）

struct DashboardPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "概览",
            systemImage: "square.grid.2x2",
            description: Text("业务屏幕将在 Phase 1/2 生成")
        )
    }
}

struct SettingsPlaceholderView: View {
    var body: some View {
        ContentUnavailableView(
            "设置",
            systemImage: "gearshape",
            description: Text("业务屏幕将在 Phase 1/2 生成")
        )
    }
}

#Preview {
    ContentView()
}
```

#### 全屏布局

```swift
// App/ContentView.swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        FullScreenPlaceholderView()
    }
}

// MARK: - 占位视图（Phase 1/2 替换为实际业务屏幕）

struct FullScreenPlaceholderView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: geometry.size.height * 0.2)

                    Image(systemName: "app.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)

                    VStack(spacing: 8) {
                        Text("应用名称")
                            .font(.largeTitle.bold())

                        Text("业务屏幕将在 Phase 1/2 生成")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: geometry.size.height)
                .padding(.horizontal, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .ignoresSafeArea(.keyboard)
    }
}

#Preview {
    ContentView()
}
```

### 3.3 网络层 (Services/APIClient.swift)

生成一个零依赖的网络请求客户端，基于 URLSession + async/await。

```swift
// Services/APIClient.swift
import Foundation

// MARK: - 错误类型

/// API 请求错误枚举
enum APIError: LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case serverError(statusCode: Int, data: Data?)
    case unauthorized
    case notFound
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "网络请求失败：\(error.localizedDescription)"
        case .decodingError(let error):
            return "数据解析失败：\(error.localizedDescription)"
        case .serverError(let statusCode, _):
            return "服务器错误（\(statusCode)）"
        case .unauthorized:
            return "身份认证失败，请重新登录"
        case .notFound:
            return "请求的资源不存在"
        case .invalidURL:
            return "无效的请求地址"
        }
    }
}

// MARK: - HTTP 方法

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - API 客户端

/// 网络请求客户端
/// 使用 async/await + URLSession，无第三方依赖
@Observable
final class APIClient: Sendable {

    /// 基础 URL（根据实际后端地址修改）
    static let baseURL = "https://api.example.com/v1"

    /// 共享单例
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - 通用请求方法

    /// 发起请求并解码响应
    /// - Parameters:
    ///   - path: API 路径（如 "/users"）
    ///   - method: HTTP 方法
    ///   - body: 请求体（Encodable，可选）
    ///   - queryItems: URL 查询参数（可选）
    /// - Returns: 解码后的响应对象
    func request<T: Decodable>(
        _ path: String,
        method: HTTPMethod = .get,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) async throws -> T {
        let urlRequest = try buildRequest(
            path: path,
            method: method,
            body: body,
            queryItems: queryItems
        )

        let (data, response) = try await performRequest(urlRequest)
        try validateResponse(response, data: data)

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// 发起请求，不需要解码响应体（如 DELETE）
    func requestVoid(
        _ path: String,
        method: HTTPMethod = .delete,
        body: (any Encodable)? = nil
    ) async throws {
        let urlRequest = try buildRequest(path: path, method: method, body: body)
        let (data, response) = try await performRequest(urlRequest)
        try validateResponse(response, data: data)
    }

    // MARK: - 内部方法

    private func buildRequest(
        path: String,
        method: HTTPMethod,
        body: (any Encodable)? = nil,
        queryItems: [URLQueryItem]? = nil
    ) throws -> URLRequest {
        guard var components = URLComponents(string: Self.baseURL + path) else {
            throw APIError.invalidURL
        }

        if let queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // 注入认证 Token（如已登录）
        if let token = TokenStore.getAccessToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            request.httpBody = try encoder.encode(body)
        }

        return request
    }

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch {
            throw APIError.networkError(error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }

        switch httpResponse.statusCode {
        case 200...299:
            return // 成功
        case 401:
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        default:
            throw APIError.serverError(statusCode: httpResponse.statusCode, data: data)
        }
    }
}

// MARK: - Token 存储（开发阶段使用 UserDefaults，生产环境替换为 Keychain）

enum TokenStore {
    private static let accessTokenKey = "api_access_token"

    static func getAccessToken() -> String? {
        UserDefaults.standard.string(forKey: accessTokenKey)
    }

    static func setAccessToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: accessTokenKey)
    }

    static func removeAccessToken() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
    }
}
```

### 3.4 认证服务占位 (Services/AuthService.swift)

生成认证服务的骨架，所有方法为占位实现，由 Phase 1/2 填充真实逻辑。

```swift
// Services/AuthService.swift
import Foundation
import SwiftUI

/// 用户模型（占位，Phase 1/2 根据实际需求调整字段）
struct User: Codable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let email: String
}

/// 认证服务
/// 管理用户的登录状态和认证令牌
/// 所有方法为占位实现，Phase 1/2 接入真实 API 后填充
@Observable
final class AuthService {

    static let shared = AuthService()

    /// 当前登录用户（nil 表示未登录）
    var currentUser: User?

    /// 是否已认证
    var isAuthenticated: Bool {
        currentUser != nil
    }

    /// 登录状态加载中
    var isLoading = false

    /// 最近的错误
    var error: Error?

    private init() {}

    // MARK: - 认证方法（占位）

    /// 邮箱密码登录
    func login(email: String, password: String) async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }

        // TODO: Phase 1/2 - 替换为真实 API 调用
        // let response: LoginResponse = try await APIClient.shared.request(
        //     "/auth/login",
        //     method: .post,
        //     body: LoginRequest(email: email, password: password)
        // )
        // TokenStore.setAccessToken(response.token)
        // currentUser = response.user

        fatalError("AuthService.login 尚未实现，请在 Phase 1/2 接入真实 API")
    }

    /// 退出登录
    func logout() {
        TokenStore.removeAccessToken()
        currentUser = nil
    }

    /// 检查当前认证状态（App 启动时调用）
    func checkAuth() async {
        guard TokenStore.getAccessToken() != nil else {
            currentUser = nil
            return
        }

        // TODO: Phase 1/2 - 替换为真实 API 调用
        // do {
        //     currentUser = try await APIClient.shared.request("/auth/me")
        // } catch {
        //     logout()
        // }
    }
}
```

### 3.5 通用扩展 (Utils/Extensions.swift)

仅包含高频使用的工具扩展，保持精简。

```swift
// Utils/Extensions.swift
import SwiftUI

// MARK: - View 扩展

extension View {
    /// 收起键盘
    func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }

    /// 条件修饰符：仅在条件为 true 时应用
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Date 扩展

extension Date {
    /// 格式化为 "yyyy-MM-dd" 字符串
    var dateString: String {
        formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
    }

    /// 格式化为 "yyyy-MM-dd HH:mm" 字符串
    var dateTimeString: String {
        formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).hour().minute())
    }
}

// MARK: - Optional<String> 扩展

extension Optional where Wrapped == String {
    /// 字符串为 nil 或空时返回 true
    var isNilOrEmpty: Bool {
        switch self {
        case .none:
            return true
        case .some(let value):
            return value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
```

---

## 4. 生成流程

Phase 0 的执行顺序：

```
Step 1: 确认项目信息
  ├── 检测 .xcodeproj 或 Package.swift
  ├── 读取 {ProjectName}App.swift 获取项目名
  └── 确认项目根目录路径

Step 2: 询问导航模式
  ├── 展示 3 种选项（默认 TabBar + NavigationStack）
  └── 用户选择或确认默认

Step 3: 创建目录结构
  ├── 创建 App/, Models/, ViewModels/, Views/, Services/, Utils/, Resources/
  └── 在空目录放置 .gitkeep

Step 4: 生成基础文件
  ├── App/ContentView.swift        ← 基于用户选择的导航模式
  ├── Services/APIClient.swift     ← 网络客户端（3.3 节）
  ├── Services/AuthService.swift   ← 认证占位（3.4 节）
  └── Utils/Extensions.swift       ← 通用扩展（3.5 节）

Step 5: 更新 App 入口（如需要）
  └── 确认 {ProjectName}App.swift 的 @main body 指向新的 ContentView
```

---

## 5. 用户操作指引

Phase 0 完成后，输出以下指引：

```markdown
## Phase 0 完成 - 项目骨架已生成

### 生成的文件

| 文件路径 | 说明 |
|---------|------|
| `App/ContentView.swift` | 导航壳（{选择的模式}） |
| `Services/APIClient.swift` | 网络请求客户端 |
| `Services/AuthService.swift` | 认证服务占位 |
| `Utils/Extensions.swift` | 常用扩展工具 |

### 接入步骤

1. **导入文件到 Xcode**：
   - 将生成的文件夹拖入 Xcode 项目导航器
   - 勾选 "Create groups"（创建组，非引用）
   - 确保 Target Membership 勾选了你的 App Target

2. **删除默认 ContentView**：
   - 删除 Xcode 自动生成的旧 `ContentView.swift`
   - 新的 `App/ContentView.swift` 已替代其功能

3. **配置 Base URL**：
   - 打开 `Services/APIClient.swift`
   - 修改 `baseURL` 为实际后端地址

4. **验证运行**：
   - Cmd+R 运行项目
   - 确认导航壳正常显示（Tab 切换 / 侧栏展开）
   - 每个占位页面应显示 ContentUnavailableView

### 下一步

- 运行 **Phase 1**（UI Spec 生成）：编写业务屏幕的 Spec 文档
- 运行 **Phase 2**（代码生成）：将 Spec 转为实际页面代码，替换占位视图
```

---

## 6. 依赖说明

Phase 0 骨架**不引入任何第三方依赖**，全部使用 Apple 原生框架：

| 框架 | 用途 | 引入时机 |
|------|------|---------|
| SwiftUI | UI 构建、导航、状态管理 | Phase 0（骨架） |
| Foundation | URLSession、JSONDecoder、日期处理 | Phase 0（APIClient） |
| Swift Charts | 图表组件 | Phase 1/2（如需仪表盘屏幕） |
| PhotosUI | 图片选择器 | Phase 1/2（如需图片上传） |
| MapKit | 地图组件 | Phase 1/2（如需地图功能） |

---

## 7. 不生成的内容

以下内容由 Phase 1/2 负责，Phase 0 不生成：

| 内容 | 负责阶段 | 说明 |
|------|---------|------|
| 具体业务屏幕 | Phase 1/2 | 用户列表、详情页、表单等 |
| 数据模型定义 | Phase 1/2 | 基于 UI Spec 中的数据来源章节生成 |
| 具体 ViewModel | Phase 1/2 | 基于屏幕原型和 UI Spec 生成 |
| 具体 API 接口调用 | Phase 1/2 | 调用 APIClient 的 request 方法 |
| 表单验证逻辑 | Phase 1/2 | 在 ViewModel 中实现字段级/表单级校验 |
| 可复用子组件 | Phase 1/2 | 基于 component-mapping.md 按需生成 |
| 单元测试/UI 测试 | Phase 1/2 | 针对具体业务逻辑编写 |
| 本地化（i18n） | 按需添加 | 根据实际文案提取到 Localizable.strings |
| CI/CD 配置 | 按需添加 | Fastlane / Xcode Cloud 等 |
| 推送通知 | 按需添加 | APNs / Firebase Cloud Messaging |

---

## 8. 架构约定与设计规则

Phase 0 建立的架构约定和设计规则，Phase 1/2 生成代码时必须遵循：

### 8.1 MVVM 分层

```
View（SwiftUI View）
  │  读取状态 + 绑定输入
  ▼
ViewModel（@Observable class）
  │  业务逻辑 + 状态管理
  ▼
Service（APIClient / AuthService）
  │  网络请求 + 数据持久化
  ▼
Model（struct, Codable, Identifiable）
```

### 8.2 命名规范

| 类型 | 命名模式 | 示例 |
|------|---------|------|
| View | `{Feature}View` | `UserListView`, `OrderDetailView` |
| ViewModel | `{Feature}ViewModel` | `UserListViewModel` |
| Model | `{Entity}` 或 `{Entity}Item` | `User`, `OrderItem` |
| Service | `{Domain}Service` | `AuthService`, `PaymentService` |
| 子视图 | `{Purpose}View` 或 `{Entity}Row` | `StatCard`, `UserRow` |

### 8.3 状态管理

| 场景 | 方式 |
|------|------|
| View 内部状态 | `@State private var` |
| ViewModel 实例 | `@State private var viewModel = SomeViewModel()` |
| 跨视图传递 ViewModel | `@Bindable var viewModel: SomeViewModel` |
| 环境注入 | `@Environment(SomeService.self)` |
| 焦点管理 | `@FocusState private var` |

### 8.4 异步数据加载

所有数据加载统一使用 `.task` 修饰符触发，搭配 ViewModel 中的 `async` 方法：

```swift
// View
.task { await viewModel.loadData() }
.refreshable { await viewModel.loadData() }

// ViewModel
func loadData() async {
    isLoading = true
    defer { isLoading = false }
    do {
        data = try await APIClient.shared.request("/path")
    } catch {
        self.error = error
    }
}
```

### 8.5 设计规则遵循

Phase 0 生成的代码必须遵循 `references/design-rules.md` 中的以下规则：

| 规则编号 | 规则内容 | Phase 0 体现 |
|----------|---------|-------------|
| C1 | 只用设计系统语义色 | 所有组件使用 `.primary`, `.secondary`, `.background` 等系统语义色 |
| A1 | 语义化结构 | NavigationStack + TabView 语义正确 |
| A4 | 纯图标按钮加无障碍标签 | 所有 Image(systemName:) 按钮提供 `.accessibilityLabel()` |
| SE1 | 空数据包含图标+描述+CTA | `ContentUnavailableView` 实现 |
| SE2 | 请求失败包含错误描述+重试 | `.alert()` + 重试按钮实现 |
| DL1 | 首次加载用骨架屏 | `.redacted(reason: .placeholder)` 实现 |
| L1 | 间距基于 4px 倍数 | 所有 padding/spacing 使用 `.padding(8)` / `.padding(16)` / `.padding(24)` |
