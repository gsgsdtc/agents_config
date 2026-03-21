---
name: module-design
description: |
  模块级设计编排技能，通过 subagent 并行生成各模块 design 文档。

  触发条件：
  - "模块设计" / "开始模块设计" / "module-design"
  - "设计模块" / "生成模块设计"
  - feat 涉及多个模块，需要并行设计时

  关键词识别：模块设计、并行设计、module design、跨模块设计
version: 0.2.0
---

# Module Design

## 目的

- 识别 feat 涉及的多个模块
- 通过 subagent 并行生成各模块的详细设计
- 校验跨模块接口一致性
- 统一输出设计文档到各模块 design 目录

## 输入

| 输入项 | 说明 | 来源 |
|--------|------|------|
| project-spec.md | 项目全局规格 | `docs/spec/project-spec.md` |
| module-spec(s) | 各模块现有规格 | `docs/modules/<module>/spec.md` |
| feat 文档 | 需求文档 | `docs/feat/feat-{iid}-{slug}.md` |
| fix 历史 | 该模块历史修复记录 | `docs/modules/<module>/fix/` |

## 工作流

### 1) 识别涉及模块

**读取 project-spec §4 模块划分表**，提取所有模块信息。

**语义匹配**：分析 feat 文档内容，判断涉及哪些模块：

```
分析方法：
1. 提取 feat 中的名词（实体）→ 映射到 module-spec §3 数据模型
2. 提取 feat 中的动作 → 映射到 module-spec §4 对外接口
3. 检查 project-spec §4.1 模块依赖关系

示例：
feat "用户 OAuth 登录" →
- 实体：User → auth 模块
- 动作：OAuth 登录 → auth 模块
- 依赖：Token 校验 → api-gateway 模块（被依赖）
结果：主要模块 [auth]，关联模块 [api-gateway]
```

**输出模块列表**：
```
📋 识别到的模块：

| 模块 | 角色 | 理由 |
|------|------|------|
| auth | 主模块 | OAuth 登录核心逻辑 |
| api-gateway | 被依赖 | Token 校验复用现有逻辑 |
```

### 2) 收集上下文

为每个模块收集以下上下文（控制总量 ~10-15K tokens）：

| 上下文 | 用途 | 大小 |
|--------|------|------|
| Module Spec | 现有架构、接口、模型 | 2-5K |
| Feat 文档 | 需求细节 | 1-3K |
| Project Spec §6-7 | 项目约定、公共模块 | 2-3K |
| 依赖模块接口 | 跨模块调用契约 | 1-3K |
| Fix 历史 | 该模块近期修复记录 | ~1K |

### 3) 创建 Subagent（并行执行）

**为每个模块创建一个 subagent**，使用 Task 工具并行执行：

```yaml
# Subagent 配置
name: "feat-design-agent"
input:
  module_name: "auth"
  module_spec: "{module_spec_content}"
  feat_doc: "{feat_doc_content}"
  project_constraints: "{project_spec_sections_6_7}"
  dependency_interfaces: "{dependency_module_apis}"
  fix_history: "{fix_history_summary}"
output:
  design_doc: "{design_content}"  # 按 template-feat-design.md 格式
```

**Subagent Prompt 模板**：`prompts/feat-design-agent.md`

### 4) 校验对齐

**收集所有 subagent 输出后**，检查跨模块一致性：

| 检查项 | 说明 |
|--------|------|
| 接口匹配 | 模块A的输出 = 模块B的输入？ |
| 数据一致 | 同一实体在不同模块定义一致？ |
| 时序合理 | 跨模块调用顺序合理？ |

**发现问题时**：
- 标记不一致点
- 创建协调 subagent 重新设计冲突部分
- 或提示用户确认

### 5) 写入文档

**按模块写入设计文档**：

```bash
# 路径格式：docs/modules/<module>/design/<iid>-<slug>-design.md
docs/modules/auth/design/020-user-oauth-design.md
docs/modules/api-gateway/design/020-user-oauth-design.md  # 如涉及
```

**更新 module-spec 状态**：
- 在 module spec 的功能列表中标记相关功能状态为「设计中」

### 6) 输出总结

```
════════════════════════════════════════════════════════════════
✅ 模块设计完成

📄 生成的设计文档：
  📄 docs/modules/auth/design/020-user-oauth-design.md
  📄 docs/modules/api-gateway/design/020-user-oauth-design.md

📋 跨模块接口：
  auth → api-gateway: Token 校验接口（复用现有）

⚠️ 注意事项：
  - 各模块设计文档已通过一致性校验
  - 如后续修改，请同步更新相关模块的设计文档

📌 下一步：
  对每个设计文档运行 design-review-dev 进行代码级验证
  命令：/design-review-dev docs/modules/auth/design/020-user-oauth-design.md
════════════════════════════════════════════════════════════════
```

## Subagent 说明

### feat-design-agent

**职责**：为单个模块生成详细设计文档（feat → backend/frontend design）

**输入**：
- module_spec: 该模块现有规格
- feat_doc: 需求文档（完整或相关部分）
- project_constraints: 项目约定和约束
- dependency_interfaces: 依赖的其他模块接口
- fix_history: 该模块历史修复（用于规避重复问题）

**输出**：
- 按 `template-feat-design.md` 格式生成的设计文档内容

**Prompt 模板**：`prompts/feat-design-agent.md`

---

### fix-design-agent

**职责**：为单个模块生成修复设计文档（fix 问题文档 → fix-design）

**输入**：
- module_spec: 该模块现有规格
- fix_doc: 问题文档（现象、根因、复现步骤）
- project_constraints: 项目约定和约束
- dependency_interfaces: 依赖的其他模块接口（若修复涉及跨模块）
- related_fixes: 该模块历史修复记录（避坑）

**输出**：
- 按 `template-fix-design.md` 格式生成的修复设计文档
- 路径：`docs/modules/{module}/design/fix-{iid}-{slug}-design.md`

**Prompt 模板**：`prompts/fix-design-agent.md`

---

### dev-agent

**职责**：基于设计文档执行 TDD 开发（design → code）

**输入**：
- design_doc: 设计文档（backend-design.md 或 fix-design.md）
- module_spec: 该模块现有规格（了解现有架构）
- project_constraints: 项目约定（代码风格、错误码规范、目录结构）
- shared_modules: 公共模块说明（可复用能力）
- dependency_interfaces: 依赖模块的接口签名（调用契约）

**输出**：
- 实现代码（接口、模型、业务逻辑）
- 测试文件（先写测试再写实现）
- 开发完成报告（实现清单 + 设计偏差 + 测试结果）

**执行方式**：RED → GREEN → REFACTOR 循环

**Prompt 模板**：`prompts/dev-agent.md`

## 目录结构

```
docs/
├── modules/
│   ├── auth/
│   │   ├── spec.md              # 模块规格（活文档）
│   │   ├── design/              # 设计文档
│   │   │   └── 020-user-oauth-design.md  # ← 生成
│   │   └── fix/                 # 修复文档
│   └── .../
└── feat/
    └── 020-user-oauth.md        # 需求文档（输入）
```

## 资源

| Prompt 文件 | 对应阶段 | 模板参考 |
|------------|---------|---------|
| `prompts/feat-design-agent.md` | feat → backend/frontend design | `docs/template-feat-design.md` |
| `prompts/fix-design-agent.md` | fix → fix-design | `docs/template-fix-design.md` |
| `prompts/dev-agent.md` | design → code（TDD） | 无模板，输出代码文件 |
