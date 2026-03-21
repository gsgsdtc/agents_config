# UI 设计规则（多平台通用）

> 这些规则编码了"设计直觉"，确保无设计师也能输出高质量 UI。
> 生成代码时**必须**逐条校验，不符合的必须修正。
> 每条规则提供三平台参考实现，按目标平台选用。

---

## 1. 布局规则

| # | 规则 | Web (Tailwind) | iOS (SwiftUI) | Android (Compose) |
|---|------|----------------|---------------|-------------------|
| L1 | 所有间距基于 4px 倍数（8pt 网格） | `gap-2`=8px, `gap-4`=16px | `.padding(8)`, `.spacing: 16` | `Spacer(modifier = Modifier.height(8.dp))` |
| L2 | 主内容区最大宽度约束，居中 | `max-w-7xl mx-auto` | `.frame(maxWidth: 700)` (iPad) | `Modifier.widthIn(max = 840.dp)` |
| L3 | 页面内边距：紧凑 16px，常规 24px，宽松 32px | `px-4 md:px-6 lg:px-8` | `.padding(.horizontal, 16)` | `Modifier.padding(horizontal = 16.dp)` |
| L4 | 侧栏/导航宽度 240-280px，可折叠 | `w-64` / `w-[280px]` | `NavigationSplitView` columnWidth | `NavigationDrawer` 宽度 |
| L5 | 卡片间距 16-24px | `gap-4` / `gap-6` | `LazyVGrid(spacing: 16)` | `Arrangement.spacedBy(16.dp)` |
| L6 | 内容区顶部距导航 24px | `mt-6` | `.padding(.top, 24)` | `Modifier.padding(top = 24.dp)` |
| L7 | 区域之间间距 32px | `space-y-8` | `VStack(spacing: 32)` | `Arrangement.spacedBy(32.dp)` |
| L8 | 弹窗最大宽度 640px，垂直居中 | `max-w-2xl` Dialog | `.sheet` / `.alert()` 系统管理 | `AlertDialog` 系统管理 |

## 2. 排版规则

| # | 规则 | Web (Tailwind) | iOS (SwiftUI) | Android (Compose) |
|---|------|----------------|---------------|-------------------|
| T1 | 页面标题: 24px 加粗 | `text-2xl font-bold` | `.font(.title).bold()` | `MaterialTheme.typography.headlineMedium` |
| T2 | 区域标题: 20px 半粗 | `text-xl font-semibold` | `.font(.title2)` | `MaterialTheme.typography.titleLarge` |
| T3 | 小标题: 18px 中等 | `text-lg font-medium` | `.font(.title3)` | `MaterialTheme.typography.titleMedium` |
| T4 | 正文/表格: 14-16px | `text-sm` | `.font(.body)` | `MaterialTheme.typography.bodyMedium` |
| T5 | 标签/辅助文字: 14px + 弱色 | `text-sm text-muted-foreground` | `.font(.caption).foregroundStyle(.secondary)` | `MaterialTheme.typography.labelMedium` + `onSurfaceVariant` |
| T6 | 行高：正文 1.5，标题 1.2 | `leading-normal` / `leading-tight` | 系统默认 | 系统默认 |

## 3. 配色规则

| # | 规则 | Web | iOS | Android |
|---|------|-----|-----|---------|
| C1 | **只用设计系统语义色**，禁止硬编码颜色 | shadcn CSS 变量 (`bg-background`, `text-foreground`) | 系统颜色 (`.primary`, `.secondary`, `.background`) | MaterialTheme 语义色 (`colorScheme.primary`, `.surface`) |
| C2 | 每个视口只有**一个主要 CTA** | `variant="default"`，其余 `outline`/`ghost` | `.borderedProminent`，其余 `.bordered`/`.plain` | `Button`，其余 `OutlinedButton`/`TextButton` |
| C3 | 卡片/区块背景用次级背景色 | `bg-muted/50` / `bg-card` | `Color(.secondarySystemBackground)` | `MaterialTheme.colorScheme.surfaceVariant` |
| C4 | destructive 仅用于删除/危险操作 | `variant="destructive"` | `.tint(.red)` / `role: .destructive` | `colors = ButtonDefaults.buttonColors(containerColor = colorScheme.error)` |
| C5 | 状态语义色一致：成功=绿, 警告=琥珀, 错误=红, 信息=蓝 | 通用原则，三平台均适用 | — | — |

## 4. 组件选择规则

| # | 场景 | 选择 | 不选 |
|---|------|------|------|
| CS1 | 数据列 > 4 列 | 表格/列表（Web: DataTable, iOS: List, Android: LazyColumn+Row） | 卡片网格 |
| CS2 | 数据 <= 4 个字段 | 卡片网格（Web: Card Grid, iOS: LazyVGrid, Android: LazyVerticalGrid） | 表格 |
| CS3 | 表单标签位置 | 标签在输入框上方（iOS 中 Form Section 自动处理） | 内联标签（开关/Toggle 除外） |
| CS4 | 主操作按钮 | Web: `default`, iOS: `.borderedProminent`, Android: `Button` (filled) | 次要样式 |
| CS5 | 次要操作按钮 | Web: `outline`, iOS: `.bordered`, Android: `OutlinedButton` | 主要样式 |
| CS6 | 三级操作/图标按钮 | Web: `ghost size="icon"`, iOS: `.plain`, Android: `IconButton` | 其他 |
| CS7 | 确认危险操作 | Web: AlertDialog, iOS: `.confirmationDialog()`, Android: `AlertDialog` | 普通对话框 |
| CS8 | 成功反馈 | Web: Toast, iOS: `.alert()` 或 banner, Android: `Snackbar` | 弹窗/对话框 |

## 5. 搜索筛选规则

| # | 规则 | Web | iOS | Android |
|---|------|-----|-----|---------|
| SF1 | 搜索框 + 筛选项布局合理 | `flex items-center gap-4` 同行 | `.searchable` + `.toolbar` | `SearchBar` + `FilterChip` 行 |
| SF2 | 搜索框用 300ms 防抖 | `useDebouncedValue` hook | `.searchable` 内置 | `snapshotFlow` + `debounce(300)` |
| SF3 | 筛选项变更立即生效 | `onChange` 触发查询 | Picker `onChange` | FilterChip `onSelected` |
| SF4 | 搜索框 placeholder 提示可搜索字段 | `placeholder="搜索用户名、邮箱..."` | `prompt: "搜索用户名、邮箱..."` | `placeholder = { Text("搜索用户名、邮箱...") }` |

## 6. 数据加载规则

| # | 场景 | 选择 | 不选 |
|---|------|------|------|
| DL1 | 页面首次加载 | 骨架屏（Web: Skeleton, iOS: `.redacted`, Android: Shimmer） | Spinner 转圈 |
| DL2 | 按钮提交中 | 按钮内 Spinner + disabled | 全页 loading |
| DL3 | 分页数据 | 服务端分页 + 分页控件 | 无限滚动（移动端除外） |
| DL4 | Feed 流 / 移动端列表 | 无限滚动（iOS: `.onAppear`, Android: `LazyColumn` 触底） | 分页控件 |

## 7. 空状态和错误规则

| # | 状态 | 必须包含 | 平台实现 |
|---|------|---------|---------|
| SE1 | 空数据 | 图标 + 描述文案 + CTA 按钮 | Web: 自定义, iOS: `ContentUnavailableView`, Android: 自定义 EmptyState |
| SE2 | 请求失败 | 错误描述 + 重试按钮 | Web: error.tsx, iOS: `.alert()` + 重试, Android: `Snackbar` + 重试 |
| SE3 | 表单验证失败 | 字段下方红色提示，不用 Toast | Web: 字段下方, iOS: 字段下方 Text, Android: `supportingText` 错误态 |
| SE4 | 操作成功 | 轻量提示，自动消失 | Web: Toast, iOS: `.alert()` 或 banner, Android: `Snackbar` |

## 8. 响应式 / 自适应规则

| # | 规则 | Web | iOS | Android |
|---|------|-----|-----|---------|
| R1 | Mobile-first / 小屏优先 | 默认样式=移动端 | iPhone 为基准，iPad 通过 `horizontalSizeClass` 适配 | 手机为基准，平板通过 `WindowSizeClass` 适配 |
| R2 | 大屏展示更多内容 | `lg:block hidden`（侧栏） | `NavigationSplitView`（iPad） | `ListDetailPaneScaffold`（平板） |
| R3 | 表格/数据在小屏可横滚或折叠 | `overflow-x-auto` | List 自动适配 | `horizontalScroll` |
| R4 | 按钮在小屏占满宽度 | `w-full sm:w-auto` | `.frame(maxWidth: .infinity)` 条件应用 | `Modifier.fillMaxWidth()` 条件应用 |

## 9. 无障碍规则

| # | 规则 | Web | iOS | Android |
|---|------|-----|-----|---------|
| A1 | 使用语义化结构 | `<main>`, `<nav>`, `<section>` | VoiceOver 自动识别 SwiftUI 组件 | Compose semantics + TalkBack |
| A2 | 所有输入框关联 Label | `<Label htmlFor="xxx">` | `TextField` 自带 label | `OutlinedTextField(label = ...)` |
| A3 | 可交互元素有 focus 样式 | `focus-visible` (shadcn 默认) | 系统默认 focus 环 | `focusable()` + `indication()` |
| A4 | 纯图标按钮加无障碍标签 | `aria-label="删除"` | `.accessibilityLabel("删除")` | `contentDescription = "删除"` |
| A5 | 颜色不能是唯一状态指示 | 徽章要有文字 | Badge 配文字 | Badge 配文字 |
