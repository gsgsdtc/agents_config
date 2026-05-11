---
name: ui-gen
description: |
  将前端设计文档 (frontend-design.md) 转化为完整的前端代码，支持三个平台：
  - Web: Next.js + Tailwind + shadcn/ui
  - iOS: SwiftUI (iOS 17+)
  - Android: Jetpack Compose + Material 3

  无需设计师团队，通过内置设计规则确保 7-8/10 的 UI 质量。

  工作流分三阶段：
  - Phase 0（项目骨架初始化）：首次创建前端/客户端项目骨架
  - Phase 1（前端设计验证）：读取 frontend-design.md，验证完整性，补全缺失信息
  - Phase 2（代码生成）：从 frontend-design 整体生成代码（先共享基础设施，后逐页面填充）

  触发条件（匹配以下任一模式即使用此skill）：
  - "生成UI" / "生成页面" / "ui-gen" / "generate UI"
  - "从前端设计生成" / "实现前端设计" / "前端设计转代码"
  - "创建页面代码" / "生成前端页面" / "生成屏幕"
  - "从设计文档生成UI" / "设计转代码"
  - "生成 iOS 页面" / "SwiftUI 页面" / "iOS UI" / "生成 SwiftUI"
  - "生成 Android 页面" / "Compose 页面" / "Android UI" / "生成 Compose"
  - "初始化前端项目" / "创建 Web 项目" / "新建 iOS 项目" / "初始化 Android 项目"
  - "前端骨架" / "客户端骨架" / "frontend init" / "项目骨架"
  - 用户提供 frontend-design.md 文档并要求生成代码
  - 用户打开 *-frontend-design.md 文件并提到"生成"/"实现"

  关键词识别：UI生成、页面生成、ui-gen、generate page、前端页面、设计转代码、frontend-design、SwiftUI、Compose、iOS页面、Android页面、前端初始化、项目骨架、frontend init
version: 0.6.0
---

# UI Gen — 多平台前端代码生成

## 目的

将前端设计文档 (frontend-design.md) 转化为完整的生产可用前端代码，支持 Web、iOS、Android 三个平台。

```
┌─────────────────────────────────────────────────────┐
│                    工作流定位                          │
├─────────────────────────────────────────────────────┤
│                                                      │
│  design-review-dev                                   │
│      ├── (后端) → 直接开发                           │
│      └── (前端) → ui-gen → 生成前端代码              │
│                             │                        │
│               ┌─────────────┼─────────────┐          │
│               ▼             ▼             ▼          │
│          Phase 0       Phase 1       Phase 2         │
│        项目骨架初始化  前端设计验证   代码生成         │
│        (首次初始化)   (完整性检查)  (整体生成)        │
│               │             │             │          │
│               └─────────────┴──────┬──────┘          │
│                                    ▼                 │
│                 design-review-dev → spec-sync       │
│                                                      │
└─────────────────────────────────────────────────────┘
```

## 平台技术栈

| 层 | Web | iOS | Android |
|----|-----|-----|---------|
| 框架 | Next.js (App Router) | SwiftUI (iOS 17+) | Jetpack Compose |
| 样式 | Tailwind CSS | SwiftUI 修饰符 | Material 3 Theme |
| 组件库 | shadcn/ui | SwiftUI 原生 | Material 3 |
| 表单 | react-hook-form + zod | SwiftUI Form | Compose State + validation |
| 列表/表格 | @tanstack/react-table | List + ForEach | LazyColumn |
| 图标 | lucide-react | SF Symbols | Material Icons |
| 图表 | recharts | Swift Charts | Vico |
| 架构 | RSC (Server/Client) | MVVM (@Observable) | MVVM (ViewModel + StateFlow) |
| 导航 | Next.js Router | NavigationStack | Navigation Compose |

## 三阶段工作流

```
═══════════════════════════════════════════════════════
                      UI Gen (v0.6.0)
═══════════════════════════════════════════════════════

  用户输入
    │
    ├── 已有项目 + 已有 frontend-design → Phase 2（代码生成）
    ├── 已有项目 + 无 frontend-design   → Phase 1（设计验证/补全）
    └── 无项目 / 空项目                  → Phase 0（项目骨架初始化）
                                           ↓
                                        Phase 1 → Phase 2

══════════════════════════════════════════════════

  Phase 0: 项目骨架初始化（不变）
  ──────────────────────────────
    0) 平台识别（自动检测 / 用户指定）
    1) 骨架类型选择（参考 scaffold 模板）
    2) 项目信息收集（名称、导航结构）
    3) 生成骨架文件（目录 + 基础代码）
    4) 输出初始化摘要 + 引导进入 Phase 1

══════════════════════════════════════════════════

  Phase 1: 前端设计验证与补全
  ────────────────────────────
    0) 平台识别（从 frontend-design 头部读取 / 自动检测）
    1) 读取 frontend-design.md
    2) 验证完整性（10 个章节的代码生成就绪度）
    3) 补全缺失信息（交互式）
    4) 确认后输出"可以生成"状态

══════════════════════════════════════════════════

  Phase 2: 代码生成（从 frontend-design 整体生成）
  ─────────────────────────────────────────
    1) 解析设计文档 + 生成共享基础设施
       ├── 解析 frontend-design → 提取生成计划
       ├── 路由配置（§6）
       ├── 布局组件（§2 线框图 + §8 响应式）
       ├── 共享组件（§3.2）
       ├── 状态管理（§4）
       └── API 层（§5）
    2) 逐页面生成（按 §2.1 优先级排序）
       ├── 页面组件（§2.2 线框图 + §3.3 专属组件）
       ├── 页面内交互（§7）
       └── 页面数据获取（§5.1）
    3) 验证与输出
       ├── 跨页面集成验证（§2.3 + §6.2）
       ├── 自检（设计规则 + 状态 + 代码质量）
       └── 输出摘要
```

---

## Phase 0: 项目骨架初始化

### 触发条件

以下情况自动进入 Phase 0（而非 Phase 1）：

1. **空项目检测**：项目目录为空或不含前端/客户端代码（无 `package.json`、`.xcodeproj`、`build.gradle`）
2. **用户明确请求**："初始化前端项目"/"创建 Web 项目"/"新建 iOS 项目"/"初始化 Android 项目"/"前端骨架"/"frontend init"
3. **上游衔接**：从 design-review-dev 衔接过来，首次生成前端，项目中还没有前端骨架

### Step 0: 平台识别

同 Phase 1 的 Step 0，检测或询问目标平台。

### Step 1: 骨架类型选择

根据平台读取对应的 scaffold 模板，向用户展示可选的导航结构：

| 平台 | Scaffold 模板 | 可选导航结构 |
|------|--------------|-------------|
| Web | `@assets/scaffolds/web-scaffold.md` | 侧栏布局 / 顶栏布局 / 全宽布局 |
| iOS | `@assets/scaffolds/ios-scaffold.md` | TabBar+NavigationStack / Sidebar+NavigationSplitView / 全屏 |
| Android | `@assets/scaffolds/android-scaffold.md` | BottomNav+NavHost / NavigationDrawer / 全屏 |

### Step 2: 项目信息收集

询问用户：

| 信息 | Web | iOS | Android |
|------|-----|-----|---------|
| 项目名称 | `package.json` name | Xcode target name | applicationId |
| 导航结构 | 侧栏/顶栏/全宽 | TabBar/Sidebar/全屏 | BottomNav/Drawer/全屏 |
| Tab/导航项 | 导航菜单项列表 | Tab 标签列表 | 底部导航项列表 |

### Step 3: 生成骨架文件

按 scaffold 模板中的规则生成项目骨架：

- **Web**：目录结构 + `package.json` + `layout.tsx` + 导航组件 + API 层 + 登录占位 + shadcn/ui 基础组件
- **iOS**：注入目录结构 + `ContentView.swift` 导航壳 + `APIClient.swift` + `AuthService.swift` + Extensions
- **Android**：注入目录结构 + `AppNavigation.kt` + `Routes.kt` + `ApiClient.kt` + 通用状态组件（EmptyState/ErrorState/LoadingShimmer）

### Step 4: 输出初始化摘要

```markdown
## 项目骨架初始化完成

### 平台：{Web / iOS / Android}
### 导航结构：{选择的导航结构}

### 生成文件清单

| 文件 | 说明 |
|------|------|
| ... | ... |

### 依赖安装

{平台对应的安装指令}

### 下一步

项目骨架已就绪，现在可以：
1. 进入 Phase 1 — 验证前端设计文档完整性
2. 或直接进入 Phase 2 — 从 frontend-design.md 生成代码
```

**Phase 0 完成后自动引导进入 Phase 1。**

---

## Phase 1: 前端设计验证与补全

### Step 0: 平台识别

```
用户输入 / 项目上下文
  │
  ├── 用户明确指定 "Web" / "Next.js"         → Web
  ├── 用户明确指定 "iOS" / "SwiftUI"         → iOS
  ├── 用户明确指定 "Android" / "Compose"     → Android
  ├── frontend-design.md 头部标注             → 从文档读取
  ├── 检测到 package.json                    → Web
  ├── 检测到 Package.swift / .xcodeproj      → iOS
  ├── 检测到 build.gradle / build.gradle.kts → Android
  └── 未明确                                 → 询问用户选择平台
```

### Step 1: 读取 frontend-design.md

- 支持用户指定文件路径
- 支持自动搜索 `docs/modules/*/design/*-frontend-design.md`
- 优先选择最近修改的文档

### Step 2: 验证完整性

检查 frontend-design.md 的各章节是否包含代码生成所需的信息：

| 章节 | 必需级别 | 缺失时处理 |
|------|----------|------------|
| §1 设计概述 | 必需 | 询问目标和约束 |
| §2.1 页面清单 | 必需 | 无法继续，必须提供 |
| §2.2 页面线框图 | 必需 | 至少 P0 页面需要线框图 |
| §2.3 页面交互关系 | 推荐 | 单页面可跳过，多页面必需 |
| §3 组件层次结构 | 推荐 | 可从线框图推断 |
| §4 状态管理设计 | 可选 | 使用平台默认策略 |
| §5 数据获取策略 | 可选 | 生成 mock 数据 |
| §6 路由设计 | 推荐 | 可从页面清单推断 |
| §7 交互流程 | 可选 | 仅生成静态页面 |
| §8 响应式设计 | 可选 | 使用默认断点策略 |

**默认状态处理规则**（当 §4 或 §5 缺失时自动应用）：

| 状态 | Web | iOS | Android |
|------|-----|-----|---------|
| 加载中 | `loading.tsx` Skeleton 骨架屏 | `.redacted(reason: .placeholder)` | Shimmer placeholder composable |
| 空数据 | 图标 + 描述文案 + CTA 按钮 | `ContentUnavailableView` + 操作按钮 | 自定义 `EmptyState` composable（图标+文字+CTA） |
| 请求失败 | `error.tsx` 错误描述 + 重试按钮 | `.alert()` + 重试按钮 | `Snackbar` + 重试按钮 |
| 表单验证 | 字段下方红色提示文字 | 字段下方红色 `Text` | `supportingText` 错误态 |
| 操作成功 | `Toast`（sonner） | `.alert()` 或自定义 banner | `Snackbar` |
| 无权限 | 隐藏入口 / 提示文案 | 隐藏入口 / 提示无权限 | 隐藏入口 / 提示无权限 |

### Step 3: 补全缺失信息

- 对"必需"但缺失的章节，交互式询问用户
- 对"推荐"但缺失的章节，提示用户并提供推断值供确认
- 对"可选"缺失的章节，使用默认值并告知用户

### Step 4: 输出确认

总结验证结果，列出将要生成的内容：

```markdown
## 前端设计验证完成

### 验证结果
| 章节 | 状态 |
|------|------|
| §1 设计概述 | ✅ |
| §2 页面原型 | ✅（{n} 个页面） |
| §3 组件结构 | ✅ / ⚠️ 从线框图推断 |
| ... | ... |

### 生成计划
- 共享基础设施：路由 + 布局 + {n} 个共享组件 + 状态管理 + API 层
- 页面：{列出页面名称和优先级}
- 跨页面集成：{n} 个页面交互关系需要验证

确认后进入 Phase 2 代码生成。
```

**Phase 1 完成标志**：用户确认验证结果后进入 Phase 2。

---

## Phase 2: 代码生成

### 入口判断

```
用户输入
  │
  ├── 指向 *-frontend-design.md 文件 → 读取文件 → Step 1
  ├── 包含 "## 1. 设计概述" → frontend-design 文档 → Step 1
  ├── 从 Phase 1 确认进入 → 直接 Step 1
  └── 其他 → 回退到 Phase 1
```

### Step 1: 解析设计文档 + 生成共享基础设施

#### 1a. 解析 frontend-design → 生成计划

从 frontend-design.md 提取以下信息并生成执行计划：

```
解析结果：
├── pages: [{name, route, type, priority, wireframe}]  ← §2
├── interactions: [{source, target, trigger, data}]      ← §2.3
├── sharedComponents: [{name, props, pages}]             ← §3.2
├── pageComponents: [{page, name, responsibility}]       ← §3.3
├── stateDesign: {layers, flows}                         ← §4
├── apiEndpoints: [{page, endpoint, method, timing}]     ← §5
├── routes: [{path, component, layout, auth}]            ← §6
├── formRules: [{field, rule, timing, error}]            ← §7
└── breakpoints: [{name, range, layoutChange}]           ← §8
```

#### 1b. 生成共享基础设施

**先于页面生成**，解决跨页面状态碎片化、路由不一致、共享组件丢失、API 集成不协调等问题。

| 生成物 | 来源章节 | Web | iOS | Android |
|--------|----------|-----|-----|---------|
| 路由配置 | §6 路由表 | `app/` 目录结构 | NavigationStack 路由 | NavHost routes |
| 布局组件 | §2 线框图 + §8 断点 | `layout.tsx` | ContentView | Scaffold |
| 共享组件 | §3.2 共享组件表 | `components/shared/` | `Shared/Components/` | `ui/components/` |
| 状态管理 | §4 状态分层表 | Context/Zustand | @Observable classes | ViewModel + StateFlow |
| API 层 | §5 API 依赖表 | fetch/SWR hooks | APIClient methods | Retrofit service |
| 权限守卫 | §6.3 受保护路由 | middleware.ts | guard modifier | NavGuard composable |

**生成规则**：
- 所有共享基础设施必须符合 `@references/design-rules.md` 中的通用设计规则

### Step 2: 逐页面生成

使用 Task 工具并行生成，每个 page-gen-agent 使用 `@prompts/{platform}-gen-agent.md` 作为 prompt。

**每个 page-gen-agent 收到的输入**：

1. **当前页面信息**：
   - 该页面的线框图（§2.2 对应部分）
   - 该页面的专属组件（§3.3 对应行）
   - 该页面的数据获取（§5.1 对应行）
   - 该页面的交互流程（§7 对应部分）

2. **全局上下文**（解决跨页面问题的关键）：
   - 共享组件清单 + import 路径（来自 Step 1）
   - 状态管理接口（§4 的 store/context 定义）
   - 路由定义（其他页面的路径，用于跳转）
   - API 层接口（已生成的 API 函数签名）
   - 页面交互关系（§2.3 中与本页相关的行）

**生成顺序**：按 §2.1 优先级排序（P0 → P1 → P2）

**平台生成文件**：

**Web**:
```
types.ts → columns.tsx → _components/*.tsx → page.tsx → loading.tsx → error.tsx
```

**iOS**:
```
Models/*.swift → ViewModels/*ViewModel.swift → Views/*View.swift → Views/Components/*.swift
```

**Android**:
```
model/*.kt → viewmodel/*ViewModel.kt → ui/screens/*Screen.kt → ui/components/*.kt
```

**复杂组件（Magic MCP 集成，仅 Web）**：

当页面包含以下复杂组件时，优先调用 Magic MCP（21st.dev）获取高质量实现：
- 自定义数据表格（带拖拽排序、列调整、虚拟滚动）
- 复杂表单控件（富文本编辑器、颜色选择器、文件上传区）
- 数据可视化（图表、仪表盘卡片、统计面板）
- 高级交互组件（日历、看板、时间线）

回退策略：Magic MCP 不可用或无匹配组件时，使用 shadcn/ui 基础组件 + Tailwind 手动实现。

### Step 3: 验证与输出

#### 3a. 跨页面集成验证

| 检查项 | 来源 | 验证方式 |
|--------|------|----------|
| 页面跳转路径正确 | §2.3 流转图 | 检查 router.push/navigate 参数匹配 §6 路由表 |
| 数据传递完整 | §2.3 数据传递表 | 检查来源页面传出 = 目标页面接收 |
| 入口条件实现 | §2.3 入口出口表 | 检查页面有权限/状态守卫 |
| 共享组件引用一致 | §3.2 | 检查各页面 import 路径统一 |
| 状态引用一致 | §4 | 检查 store/context 使用方式统一 |

#### 3b. 自检

生成代码后，逐条校验以下规则：

**通用设计规则合规**（@references/design-rules.md）

| 检查类别 | 关键检查点 |
|----------|-----------|
| 布局 | 间距一致？主内容区约束？ |
| 排版 | 标题层级正确？正文字号统一？ |
| 配色 | 使用设计系统语义色？每视口一个主 CTA？ |
| 组件 | 数据量大用列表/表格？按钮层级正确？ |
| 无障碍 | 语义化结构？标签关联？可聚焦？ |

**平台特定检查**

| Web | iOS | Android |
|-----|-----|---------|
| Tailwind class 正确 | SwiftUI 修饰符顺序合理 | Material 3 组件使用正确 |
| "use client" 仅在需要时 | @Observable 用于 ViewModel | StateFlow 用于 UI 状态 |
| 响应式断点(sm/md/lg) | iPad 适配(NavigationSplitView) | 大屏适配(WindowSizeClass) |
| loading.tsx + error.tsx | .redacted + ContentUnavailableView | shimmer + 错误状态 Composable |
| shadcn CSS 变量 | 系统颜色(.primary/.secondary) | MaterialTheme 语义色 |

**状态处理完整**

| 状态 | Web | iOS | Android |
|------|-----|-----|---------|
| 加载中 | Skeleton (loading.tsx) | .redacted(reason:) | Shimmer placeholder |
| 空数据 | 图标 + CTA | ContentUnavailableView | 自定义 EmptyState |
| 请求失败 | error.tsx + 重试 | .alert() + 重试 | Snackbar + 重试 |
| 表单验证 | 字段下方红色提示 | 字段下方红色 Text | supportingText 错误态 |
| 操作成功 | Toast | .alert() 或 banner | Snackbar |

**代码质量**

| 检查项 | Web | iOS | Android |
|--------|-----|-----|---------|
| 类型安全 | 无 any 类型 | 无 force unwrap | 无 !! 非空断言 |
| 命名 | PascalCase 组件 | PascalCase View | PascalCase Composable |
| 架构 | RSC 边界清晰 | MVVM 分离 | MVVM + 单向数据流 |

**跨页面一致性**

| 检查项 | 通过标准 |
|--------|---------|
| 页面跳转 | 所有 navigate/push 调用的路径在路由表中存在 |
| 数据传递 | 来源页面传出的数据类型 = 目标页面接收的类型 |
| 共享组件 | 所有页面 import 同一路径的共享组件 |
| 状态管理 | 全局状态通过统一接口访问，无重复定义 |
| API 调用 | 所有页面使用统一 API 层函数，无直接 fetch/URLSession/Retrofit 调用 |

#### 3c. 输出摘要

```markdown
## 生成结果

### 平台：{Web / iOS / Android}
### 来源设计：{frontend-design.md 路径}

### 共享基础设施
| 文件 | 类型 | 说明 |
|------|------|------|
| ... | 路由/布局/组件/状态/API | ... |

### 页面文件
| 页面 | 文件 | 优先级 | 说明 |
|------|------|--------|------|
| ... | ... | P0/P1 | ... |

### 跨页面集成验证
| 检查项 | 状态 |
|--------|------|
| 页面跳转 | ✅ / ⚠️ |
| 数据传递 | ✅ / ⚠️ |
| 共享组件引用 | ✅ / ⚠️ |
| 状态管理一致 | ✅ / ⚠️ |
| API 调用统一 | ✅ / ⚠️ |

### 依赖安装

{平台对应的安装指令}

### 下一步建议
1. 安装依赖
2. 运行 design-review-dev（代码审查 + E2E）
3. 连接真实 API（替换 mock 数据）
4. E2E 测试（基于 §9 测试方案）
```

---

## 参考文件

### 骨架模板（Phase 0）

| 文件 | 用途 |
|------|------|
| `assets/scaffolds/web-scaffold.md` | Web (Next.js) 项目骨架生成规则 |
| `assets/scaffolds/ios-scaffold.md` | iOS (SwiftUI) 项目增强规则 |
| `assets/scaffolds/android-scaffold.md` | Android (Compose) 项目增强规则 |

### 共享文件

| 文件 | 用途 |
|------|------|
| `references/design-rules.md` | 通用设计规则（40 条，9 类） |
| `references/design-concepts.md` | 设计概念：色彩/排版/动效/布局/品牌 |
| `references/perf-rules.md` | React/Next.js 性能规则（45 条，8 类） |

### 设计概念（来自 designer）

Phase 2 生成代码时应用以下设计概念：

| 概念 | 风格 |
|------|------|
| Apple Glassmorphism | 半透明磨砂、景深感 |
| Neo-Brutalism | 高对比、粗边框、原始感 |
| Claymorphism | 柔和 3D、膨胀感 |
| Aurora Gradients | 动态模糊色彩网格 |
| Bento Grids | 模块化网格布局 |

### 素材生成（来自 designer）

需生成图标/插画/头像时：
1. `generate_image` — 按 `[主题] + [风格] + [光照/色彩] + [质量]` 公式生成
2. `python3 scripts/remove_background.py <in> <out>` — 移除背景

### 性能规则（来自 react-best-practices）

代码生成时自动应用以下规则（按优先级）：

| 优先级 | 类别 | 示例规则 |
|--------|------|---------|
| 1 CRITICAL | 消除请求瀑布 | `Promise.all()` 并行、Suspense 流式 |
| 2 CRITICAL | Bundle 优化 | 避免 barrel import、next/dynamic 懒加载 |
| 3 HIGH | 服务端性能 | React.cache()、LRU 缓存、最小化序列化 |
| 4 MEDIUM | 客户端请求 | SWR 去重、事件监听去重 |
| 5 MEDIUM | 重渲染优化 | memo、useTransition、functional setState |
| 6 LOW | JS 性能 | Set/Map 查找、提前返回、正则提升 |

### 平台专属文件

| 平台 | Prompt |
|------|--------|
| Web | `prompts/web-gen-agent.md` |
| iOS | `prompts/ios-gen-agent.md` |
| Android | `prompts/android-gen-agent.md` |

## 与其他 Skill 的协作

| 上游 Skill | 产出 → 输入 |
|------------|------------|
| feat-review-design | frontend-design.md → ui-gen 输入 |
| design-review-dev | Review 通过 → 触发 UI 生成 |

| 下游 Skill | 输出 → 输入 |
|------------|------------|
| design-review-dev | 生成代码 → 代码审查 + E2E |
| spec-sync | 开发完成 → 回写 Spec |
