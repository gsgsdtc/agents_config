# 大单元测试（Broad Unit Test）Skill

> **一句话概括**：以 API Endpoint 为粒度，只 Mock 系统边界，验证业务契约的测试方法。

## 🎯 核心理念

测试完整的业务链路，而非孤立的函数。让你敢于重构！⚙️

| 小单元测试 | **大单元测试** ✅ | 集成测试 |
|-----------|---------------|---------|
| 测试单个函数 | **测试完整 API** | 测试整个系统 |
| Mock 所有依赖 | **只 Mock 边界** | 几乎不 Mock |
| 改函数名就挂 | **重构不挂** | 极其稳定 |

## 📁 文件结构

```
~/.claude/skills/broad-unit-test/
├── SKILL.md                      # 主文档（概念、原则、快速开始）
├── README.md                     # 本文件
├── templates/                    # 语言/框架测试模板
│   ├── python-flask.md           # Flask API 测试
│   ├── python-fastapi.md         # FastAPI 测试（TODO）
│   ├── python-django.md          # Django 测试（TODO）
│   ├── go-stdlib.md              # Go net/http 测试
│   ├── go-gin.md                 # Gin 测试（TODO）
│   ├── java-spring.md            # Spring Boot 测试
│   └── java-jaxrs.md             # JAX-RS 测试（TODO）
├── examples/                     # 真实示例
│   ├── python-vlog-api.md        # Python Vlog 生成接口
│   ├── go-user-api.md            # Go 用户认证接口（TODO）
│   └── java-order-api.md         # Java 订单处理接口（TODO）
├── references/                   # 参考文档
│   ├── comparison.md             # 与小单元/集成测试的对比
│   ├── mock-boundaries.md        # Mock 边界识别指南（TODO）
│   └── test-patterns.md          # 测试模式详解（TODO）
└── tools/                        # 工具脚本
    └── framework-detector.sh     # 自动检测框架类型（TODO）
```

## 🚀 快速开始

### 1. 选择模板

| 语言 | 框架 | 模板 |
|------|------|------|
| Python | Flask | [templates/python-flask.md](templates/python-flask.md) |
| Python | FastAPI | [templates/python-fastapi.md](templates/python-fastapi.md) ⏳ |
| Python | Django | [templates/python-django.md](templates/python-django.md) ⏳ |
| Go | net/http | [templates/go-stdlib.md](templates/go-stdlib.md) |
| Go | Gin | [templates/go-gin.md](templates/go-gin.md) ⏳ |
| Java | Spring Boot | [templates/java-spring.md](templates/java-spring.md) |
| Java | JAX-RS | [templates/java-jaxrs.md](templates/java-jaxrs.md) ⏳ |

### 2. 参考示例

| 示例 | 语言 | 业务场景 |
|------|------|---------|
| [Python Vlog API](examples/python-vlog-api.md) | Python Flask | Vlog 视频生成（包含重试逻辑、参数验证、错误处理） |
| [Go User API](examples/go-user-api.md) ⏳ | Go net/http | 用户认证（包含 JWT、密码验证） |
| [Java Order API](examples/java-order-api.md) ⏳ | Java Spring Boot | 订单处理（包含库存检查、价格计算） |

### 3. 阅读对比

阅读 [references/comparison.md](references/comparison.md) 理解大单元测试与其他测试类型的区别。

## 📖 核心文档

### [SKILL.md](SKILL.md) - 主文档

包含：
- 概述和核心原则
- 何时使用
- 支持的语言和框架
- 测试模式（AAA、Given-When-Then）
- 快速开始指南
- 常见问题

### [references/comparison.md](references/comparison.md) - 对比文档

包含：
- 小单元测试 vs 大单元测试 vs 集成测试
- 测试粒度、Mock 策略、重构友好度对比
- 推荐的测试奖杯模型（Testing Trophy）：70% 大单元测试
- 何时使用哪种测试

## 🎓 学习路径

### 初学者

1. 阅读 [SKILL.md](SKILL.md) 理解概念
2. 阅读 [references/comparison.md](references/comparison.md) 理解对比
3. 参考 [examples/python-vlog-api.md](examples/python-vlog-api.md) 看真实示例
4. 选择对应的模板开始编写测试

### 进阶使用者

1. 参考模板编写自己的测试
2. 阅读参考文档深入理解 Mock 边界识别
3. 探索不同测试模式的使用场景
4. 贡献新的模板和示例

## 🛠️ 待完成

| 优先级 | 内容 | 状态 |
|--------|------|------|
| P0 | Python Flask 模板 | ✅ 完成 |
| P0 | Go net/http 模板 | ✅ 完成 |
| P0 | Java Spring Boot 模板 | ✅ 完成 |
| P0 | Python Vlog API 示例 | ✅ 完成 |
| P0 | 对比文档 | ✅ 完成 |
| P1 | Python FastAPI 模板 | ⏳ TODO |
| P1 | Python Django 模板 | ⏳ TODO |
| P1 | Go Gin 模板 | ⏳ TODO |
| P1 | Java JAX-RS 模板 | ⏳ TODO |
| P2 | Go User API 示例 | ⏳ TODO |
| P2 | Java Order API 示例 | ⏳ TODO |
| P2 | Mock 边界识别指南 | ⏳ TODO |
| P2 | 测试模式详解 | ⏳ TODO |
| P3 | 框架自动检测工具 | ⏳ TODO |

## 🤝 贡献

欢迎贡献新的模板、示例和参考文档！

### 模板贡献指南

1. **命名规范**：`{language}-{framework}.md`（如 `python-fastapi.md`）
2. **必须包含**：
   - 测试环境配置
   - 基础测试模板
   - Mock 策略
   - 最佳实践
   - 运行测试的命令
3. **风格统一**：参考现有模板的结构

### 示例贡献指南

1. **命名规范**：`{language}-{scenario}-api.md`（如 `python-vlog-api.md`）
2. **必须包含**：
   - 业务场景描述
   - 被测试的代码
   - 完整的测试代码
   - 关键要点说明
   - 测试覆盖的业务契约

## 📚 相关资源

- [test-driven-development skill](..//test-driven-development/) - TDD 工作流
- [python-testing skill](https://github.com/anthropics/everything-claude-code/skills/python-testing) - Python 小单元测试
- [golang-testing skill](https://github.com/anthropics/everything-claude-code/skills/golang-testing) - Go 小单元测试

---

**Remember**: 大单元测试让你锁定业务契约，自由重构内部实现。测试的是"齿轮组"，而非"螺丝钉"。⚙️
