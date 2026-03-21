# Web 项目骨架模板 (Next.js + shadcn/ui)

> 此模板由 ui-gen Phase 0 使用，生成 Next.js 前端项目的基础骨架。
> 技术栈：Next.js (App Router) + Tailwind CSS + shadcn/ui
> Phase 0 只生成项目骨架和导航壳，不生成具体业务页面。

---

## 1. 前置条件

- Node.js 18+
- pnpm（推荐）或 npm
- 两种初始化路径：
  - **路径 A**：先运行 `npx create-next-app@latest` 创建基础项目，再由本模板注入结构
  - **路径 B**：由 Claude 直接生成全部文件（适用于无法运行 CLI 的环境）
- 若用户已有项目目录，跳过项目创建，仅补充缺失的目录和文件

---

## 2. 目录结构

生成以下完整目录树。已有文件不覆盖，缺失文件按规则创建。

```
{project-root}/
├── public/                       # 静态资源
│   └── favicon.ico
├── src/
│   ├── app/
│   │   ├── (admin)/              # 管理后台路由组（侧栏布局时使用）
│   │   │   ├── layout.tsx        # 管理后台布局壳（含侧栏）
│   │   │   └── dashboard/
│   │   │       └── page.tsx      # 默认首页（占位）
│   │   ├── (auth)/               # 认证路由组（全宽布局）
│   │   │   ├── layout.tsx        # 认证布局壳（居中全宽）
│   │   │   └── login/
│   │   │       └── page.tsx      # 登录页（占位）
│   │   ├── layout.tsx            # 根布局（html + body + 字体 + ThemeProvider）
│   │   ├── page.tsx              # 首页（重定向到 /dashboard）
│   │   ├── loading.tsx           # 全局 loading
│   │   ├── not-found.tsx         # 404 页面
│   │   └── globals.css           # Tailwind 全局样式 + shadcn CSS 变量
│   ├── components/
│   │   ├── ui/                   # shadcn/ui 组件目录（由 CLI 生成，不手动编辑）
│   │   ├── sidebar.tsx           # 侧栏导航（侧栏布局时）
│   │   ├── mobile-sidebar.tsx    # 移动端侧栏（Sheet 抽屉）
│   │   └── theme-provider.tsx    # 主题切换 Provider
│   ├── lib/
│   │   ├── utils.ts              # cn() 工具函数
│   │   └── api.ts                # API 请求封装
│   ├── hooks/                    # 自定义 hooks
│   │   └── use-mobile.ts         # 移动端检测 hook
│   ├── types/                    # TypeScript 全局类型定义
│   │   └── index.ts              # 通用类型（ApiResponse, PaginatedResult 等）
│   └── config/
│       └── nav.ts                # 导航菜单配置（Single Source of Truth）
├── .env.local                    # 环境变量模板
├── .env.example                  # 环境变量示例（提交到 Git）
├── next.config.ts                # Next.js 配置
├── tailwind.config.ts            # Tailwind 配置（含 shadcn 预设）
├── tsconfig.json                 # TypeScript 配置
├── postcss.config.mjs            # PostCSS 配置
├── components.json               # shadcn/ui 配置
└── package.json
```

### 目录命名规则

| 目录 | 用途 | 约束 |
|------|------|------|
| `(admin)` | 管理后台路由组 | 使用侧栏布局，所有后台页面放在此路由组下 |
| `(auth)` | 认证路由组 | 使用全宽布局，不含导航壳 |
| `_components/` | 页面级私有组件 | 仅限特定 route 下使用，不可跨页面引用 |
| `components/` | 全局共享组件 | 可被任意页面引用 |
| `components/ui/` | shadcn/ui 组件 | 由 `npx shadcn@latest add` 管理，不手动编辑 |

---

## 3. 基础文件生成规则

### 3.1 package.json

```jsonc
{
  "name": "{project-name}",       // 用户提供或从目录名推断
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "^15",
    "react": "^19",
    "react-dom": "^19",
    "class-variance-authority": "^0.7",
    "clsx": "^2",
    "tailwind-merge": "^2",
    "lucide-react": "^0.460",
    "next-themes": "^0.4"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/react": "^19",
    "@types/react-dom": "^19",
    "@types/node": "^22",
    "tailwindcss": "^3.4",
    "postcss": "^8",
    "autoprefixer": "^10",
    "eslint": "^9",
    "eslint-config-next": "^15"
  }
}
```

**版本策略**：使用 `^` 范围锁定大版本，具体小版本由 lockfile 管理。

### 3.2 导航配置 (config/nav.ts)

此文件是侧栏和移动端导航的**唯一数据源**，所有导航组件从此处读取。

```ts
import { LayoutDashboard, type LucideIcon } from "lucide-react"

export interface NavItem {
  title: string
  href: string
  icon: LucideIcon
  disabled?: boolean
}

export const navItems: NavItem[] = [
  {
    title: "Dashboard",
    href: "/dashboard",
    icon: LayoutDashboard,
  },
  // Phase 1/2 生成的业务页面将在此追加导航项
]
```

**生成规则**：
- 默认只包含 Dashboard 一项
- 后续 Phase 1/2 生成业务页面时，同步向 `navItems` 数组追加对应条目
- 导航项顺序 = 用户看到的菜单顺序
- `disabled` 字段可用于灰显未完成的菜单项

### 3.3 布局壳选择

根据用户选择的页面级布局，从 `references/web/layout-patterns.md` 获取对应代码片段。

| 用户选择 | 对应 Pattern | 生成文件 | 备注 |
|---------|-------------|---------|------|
| 侧栏布局 | Pattern 1 (Sidebar Layout) | `(admin)/layout.tsx` + `components/sidebar.tsx` + `components/mobile-sidebar.tsx` | 后台管理默认选择 |
| 顶栏布局 | Pattern 2 (Top Nav Layout) | `(admin)/layout.tsx`（含顶部导航栏） | 面向用户的产品页面 |
| 全宽布局 | Pattern 3 (Full Width) | `(admin)/layout.tsx`（无导航壳） | 登录页、落地页 |

**默认选择**：侧栏布局。用户未指定时不询问，直接使用侧栏布局。

#### 3.3.1 侧栏布局生成细节

**`(admin)/layout.tsx`**：
- 从 `references/web/layout-patterns.md` Pattern 1 获取布局结构
- 包含桌面端侧栏 (`hidden lg:flex`) + 移动端顶栏 (`lg:hidden`)
- 移动端顶栏包含 `<MobileSidebar />` 汉堡按钮
- 主内容区使用 `flex-1 overflow-y-auto` 确保独立滚动
- 内容区内部约束 `max-w-7xl` 并设置水平/垂直 padding

**`components/sidebar.tsx`**：
- `"use client"` 客户端组件
- 从 `@/config/nav` 导入 `navItems`（不内联导航数据）
- 使用 `usePathname()` 高亮当前路由
- 顶部 Logo 区域（高度 h-14，与移动端顶栏对齐）
- 导航链接使用 `cn()` 条件样式：激活态 `bg-accent text-accent-foreground`，默认态 `text-muted-foreground hover:bg-accent`
- 底部预留用户信息/退出区域（注释占位）

**`components/mobile-sidebar.tsx`**：
- `"use client"` 客户端组件
- 使用 shadcn `<Sheet>` 组件实现侧边抽屉
- `<SheetTrigger>` 使用 `<Menu />` 图标按钮，带 `sr-only` 无障碍文本
- `<SheetContent side="left">` 内部复用 `<Sidebar />` 组件
- 仅在 `lg:hidden` 断点以下显示触发按钮

#### 3.3.2 顶栏布局生成细节

**`(admin)/layout.tsx`**：
- 从 `references/web/layout-patterns.md` Pattern 2 获取布局结构
- `<header>` 使用 `sticky top-0 z-50 border-b bg-background/95 backdrop-blur`
- 导航链接从 `@/config/nav` 读取，桌面端水平排列 (`hidden md:flex`)
- 移动端使用 Sheet 抽屉菜单
- 不生成独立的 sidebar.tsx

#### 3.3.3 全宽布局生成细节

**`(admin)/layout.tsx`**：
- 从 `references/web/layout-patterns.md` Pattern 3 获取布局结构
- 仅包含 `<main className="min-h-screen">{children}</main>`
- 不生成导航组件

### 3.4 根布局 (app/layout.tsx)

```tsx
import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "./globals.css"
import { ThemeProvider } from "@/components/theme-provider"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "{项目名称}",
  description: "{项目描述}",
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="zh-CN" suppressHydrationWarning>
      <body className={inter.className}>
        <ThemeProvider
          attribute="class"
          defaultTheme="system"
          enableSystem
          disableTransitionOnChange
        >
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
```

**生成规则**：
- `lang` 属性默认 `zh-CN`，可根据用户需求调整
- `metadata.title` 和 `description` 从用户提供的项目名/描述填充
- 字体默认 Inter，可根据项目需求替换
- `suppressHydrationWarning` 配合 next-themes 主题切换
- ThemeProvider 包裹全部子组件，支持 light/dark/system 三种模式

### 3.5 主题 Provider (components/theme-provider.tsx)

```tsx
"use client"

import * as React from "react"
import { ThemeProvider as NextThemesProvider } from "next-themes"

export function ThemeProvider({
  children,
  ...props
}: React.ComponentProps<typeof NextThemesProvider>) {
  return <NextThemesProvider {...props}>{children}</NextThemesProvider>
}
```

### 3.6 工具函数 (lib/utils.ts)

```ts
import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}
```

此文件由 `npx shadcn@latest init` 自动生成，手动创建时内容一致。

### 3.7 API 层 (lib/api.ts)

```ts
const BASE_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5000/api"

interface RequestOptions extends Omit<RequestInit, "body"> {
  body?: unknown
  params?: Record<string, string | number | undefined>
}

class ApiError extends Error {
  constructor(
    public status: number,
    message: string,
    public data?: unknown
  ) {
    super(message)
    this.name = "ApiError"
  }
}

async function request<T>(
  endpoint: string,
  { body, params, headers, ...options }: RequestOptions = {}
): Promise<T> {
  // 构建 URL（拼接查询参数）
  const url = new URL(endpoint, BASE_URL)
  if (params) {
    Object.entries(params).forEach(([key, value]) => {
      if (value !== undefined) {
        url.searchParams.set(key, String(value))
      }
    })
  }

  // 获取 Token
  const token =
    typeof window !== "undefined" ? localStorage.getItem("token") : null

  const response = await fetch(url.toString(), {
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
    ...options,
  })

  if (!response.ok) {
    const errorData = await response.json().catch(() => null)
    throw new ApiError(
      response.status,
      errorData?.message ?? `请求失败: ${response.status}`,
      errorData
    )
  }

  // 204 No Content
  if (response.status === 204) {
    return undefined as T
  }

  return response.json()
}

export const api = {
  get: <T>(endpoint: string, params?: RequestOptions["params"]) =>
    request<T>(endpoint, { method: "GET", params }),

  post: <T>(endpoint: string, body?: unknown) =>
    request<T>(endpoint, { method: "POST", body }),

  put: <T>(endpoint: string, body?: unknown) =>
    request<T>(endpoint, { method: "PUT", body }),

  patch: <T>(endpoint: string, body?: unknown) =>
    request<T>(endpoint, { method: "PATCH", body }),

  delete: <T>(endpoint: string) =>
    request<T>(endpoint, { method: "DELETE" }),
}
```

**生成规则**：
- `BASE_URL` 从 `NEXT_PUBLIC_API_URL` 环境变量读取
- Token 存储在 localStorage，通过 Bearer 方式传递
- 错误统一封装为 `ApiError`，包含 status 和 data
- 提供 get/post/put/patch/delete 五个快捷方法
- 此文件为占位基础封装，业务层可在此基础上扩展

### 3.8 通用类型 (types/index.ts)

```ts
/** 标准 API 响应 */
export interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

/** 分页结果 */
export interface PaginatedResult<T> {
  items: T[]
  total: number
  page: number
  pageSize: number
  totalPages: number
}

/** 分页请求参数 */
export interface PaginationParams {
  page?: number
  pageSize?: number
}
```

### 3.9 移动端检测 Hook (hooks/use-mobile.ts)

```ts
"use client"

import { useEffect, useState } from "react"

const MOBILE_BREAKPOINT = 1024 // lg 断点，与 sidebar 的 lg:hidden 对齐

export function useIsMobile() {
  const [isMobile, setIsMobile] = useState(false)

  useEffect(() => {
    const mql = window.matchMedia(`(max-width: ${MOBILE_BREAKPOINT - 1}px)`)
    const onChange = () => setIsMobile(mql.matches)
    mql.addEventListener("change", onChange)
    setIsMobile(mql.matches)
    return () => mql.removeEventListener("change", onChange)
  }, [])

  return isMobile
}
```

### 3.10 首页重定向 (app/page.tsx)

```tsx
import { redirect } from "next/navigation"

export default function Home() {
  redirect("/dashboard")
}
```

**规则**：首页直接重定向到 Dashboard，不展示任何内容。

### 3.11 登录页占位 (app/(auth)/login/page.tsx)

```tsx
"use client"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Label } from "@/components/ui/label"

export default function LoginPage() {
  const [isLoading, setIsLoading] = useState(false)

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault()
    setIsLoading(true)
    // TODO: 由 Phase 1/2 实现具体认证逻辑
    setIsLoading(false)
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-muted/50 px-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl">登录</CardTitle>
          <CardDescription>输入您的账号密码登录系统</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={onSubmit} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="email">邮箱</Label>
              <Input
                id="email"
                type="email"
                placeholder="name@example.com"
                required
                disabled={isLoading}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="password">密码</Label>
              <Input
                id="password"
                type="password"
                required
                disabled={isLoading}
              />
            </div>
            <Button type="submit" className="w-full" disabled={isLoading}>
              {isLoading ? "登录中..." : "登录"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}
```

**生成规则**：
- `"use client"` 因为包含表单交互状态
- 使用 shadcn 的 Input, Button, Card, Label 组件
- 表单结构完整但不含实际认证逻辑（Phase 1/2 负责）
- 居中布局来自 `references/web/layout-patterns.md` Pattern 3 的登录页样式
- 必须为每个 Input 关联 `<Label htmlFor>` 以满足无障碍要求

### 3.12 认证布局壳 (app/(auth)/layout.tsx)

```tsx
export default function AuthLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <main className="min-h-screen">
      {children}
    </main>
  )
}
```

**规则**：认证路由组使用全宽布局，不含任何导航壳。

### 3.13 Dashboard 占位 (app/(admin)/dashboard/page.tsx)

```tsx
export default function DashboardPage() {
  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Dashboard</h1>
        <p className="text-muted-foreground">
          欢迎回来。此页面内容将由后续阶段生成。
        </p>
      </div>
    </div>
  )
}
```

**生成规则**：
- Server Component（无 `"use client"`）
- 仅展示标题和占位文字
- 不包含任何统计卡片、图表等业务内容（Phase 1/2 负责）

### 3.14 全局 Loading (app/loading.tsx)

```tsx
export default function Loading() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
    </div>
  )
}
```

### 3.15 404 页面 (app/not-found.tsx)

```tsx
import Link from "next/link"
import { Button } from "@/components/ui/button"

export default function NotFound() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center text-center">
      <h1 className="text-4xl font-bold">404</h1>
      <p className="mt-2 text-muted-foreground">页面不存在</p>
      <Button asChild className="mt-6">
        <Link href="/">返回首页</Link>
      </Button>
    </div>
  )
}
```

---

## 4. shadcn/ui 初始化

### 4.1 初始化命令

```bash
npx shadcn@latest init
```

初始化时选择以下配置：
- Style: New York
- Base color: Neutral
- CSS variables: Yes

### 4.2 最小依赖组件集

布局壳正常运作所需的最小组件集：

```bash
npx shadcn@latest add button input card sheet label
```

| 组件 | 用途 | 依赖方 |
|------|------|--------|
| button | 全局通用按钮 | sidebar, login, not-found |
| input | 登录表单输入框 | login |
| card | 登录页卡片容器 | login |
| sheet | 移动端侧栏抽屉 | mobile-sidebar |
| label | 表单标签（无障碍关联） | login |

### 4.3 components.json

此文件由 `shadcn init` 自动生成，关键配置：

```jsonc
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "new-york",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "src/app/globals.css",
    "baseColor": "neutral",
    "cssVariables": true
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}
```

---

## 5. 环境配置

### 5.1 .env.local（本地开发，不提交 Git）

```env
NEXT_PUBLIC_API_URL=http://localhost:5000/api
```

### 5.2 .env.example（提交到 Git 作为模板）

```env
# API 后端地址
NEXT_PUBLIC_API_URL=http://localhost:5000/api
```

### 5.3 next.config.ts

```ts
import type { NextConfig } from "next"

const nextConfig: NextConfig = {
  reactStrictMode: true,
}

export default nextConfig
```

**生成规则**：
- 启用 `reactStrictMode`
- 不预配置 `images.remotePatterns`（按需添加）
- 不预配置 `rewrites` 或 `redirects`（按需添加）
- 保持最小配置，避免不必要的选项

### 5.4 tailwind.config.ts

由 `shadcn init` 自动生成，确保包含以下关键配置：
- `content` 路径包含 `./src/**/*.{ts,tsx}`
- 包含 shadcn 的 CSS 变量主题配置
- `darkMode: "class"` 配合 next-themes

### 5.5 tsconfig.json

确保包含路径别名：

```jsonc
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

---

## 6. 生成流程

Phase 0 按以下顺序执行：

```
1. 确认项目基本信息
   ├── 项目名称（用于 package.json name 和 metadata.title）
   ├── 项目描述（用于 metadata.description）
   └── 布局选择（默认：侧栏布局，不询问直接使用）

2. 创建目录结构
   └── 按 §2 创建所有目录

3. 生成配置文件
   ├── package.json (§3.1)
   ├── next.config.ts (§5.3)
   ├── tsconfig.json (§5.5)
   ├── postcss.config.mjs
   ├── .env.local + .env.example (§5.1, §5.2)
   └── components.json (§4.3)

4. 生成基础代码文件
   ├── lib/utils.ts (§3.6)
   ├── lib/api.ts (§3.7)
   ├── types/index.ts (§3.8)
   ├── hooks/use-mobile.ts (§3.9)
   └── config/nav.ts (§3.2)

5. 生成布局与页面
   ├── app/globals.css（Tailwind 指令 + shadcn CSS 变量）
   ├── app/layout.tsx (§3.4)
   ├── app/page.tsx (§3.10)
   ├── app/loading.tsx (§3.14)
   ├── app/not-found.tsx (§3.15)
   ├── components/theme-provider.tsx (§3.5)
   ├── 布局壳文件（按 §3.3 选择的布局模式生成）
   ├── app/(auth)/layout.tsx (§3.12)
   ├── app/(auth)/login/page.tsx (§3.11)
   └── app/(admin)/dashboard/page.tsx (§3.13)

6. 安装依赖 & shadcn 组件
   ├── pnpm install（或 npm install）
   ├── npx shadcn@latest init（若未初始化）
   └── npx shadcn@latest add button input card sheet label

7. 验证
   ├── pnpm dev 启动成功
   ├── 访问 / 自动重定向到 /dashboard
   ├── 侧栏导航可见、高亮正确
   ├── 移动端（< lg）显示汉堡菜单
   └── /login 页面正常渲染
```

---

## 7. 无障碍基线要求

Phase 0 生成的骨架必须满足以下无障碍基线：

| 要求 | 实现方式 |
|------|---------|
| 语义化 HTML | `<header>`, `<nav>`, `<main>`, `<aside>` 正确使用 |
| 键盘导航 | 所有交互元素可通过 Tab 键聚焦 |
| 跳过导航链接 | 可选：在根布局中添加 "Skip to content" 链接 |
| 图标按钮标签 | 所有图标按钮必须有 `aria-label` 或 `sr-only` 文本 |
| 表单标签关联 | 每个 `<Input>` 必须有对应的 `<Label htmlFor>` |
| 颜色对比度 | 使用 shadcn CSS 变量语义色，确保 WCAG AA 对比度 |
| 响应式文字 | 不使用固定 px 字号，使用 Tailwind 的 text-sm/base/lg 等 |

---

## 8. 不生成的内容

以下内容不属于 Phase 0，由后续阶段负责：

| 内容 | 负责阶段 |
|------|---------|
| 具体业务页面（用户管理、订单列表等） | Phase 1/2 |
| 数据模型定义（业务实体） | Phase 1/2 |
| 具体 API 接口调用（业务相关） | Phase 1/2 |
| 表格列配置（columns.tsx） | Phase 1/2 |
| 表单验证逻辑（zod schema） | Phase 1/2 |
| react-hook-form 表单集成 | Phase 1/2 |
| @tanstack/react-table 数据表格 | Phase 1/2 |
| recharts 图表 | Phase 1/2 |
| 认证/授权中间件 | Phase 1/2 |
| 国际化（i18n） | 按需添加 |
| 单元测试 / E2E 测试 | 按需添加 |
| CI/CD 配置 | 按需添加 |
| Docker 部署配置 | 按需添加 |
