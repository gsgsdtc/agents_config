#!/bin/bash
# Project Scanner for spec-extract
# 扫描项目结构，识别语言、框架和模块划分
# 用法: ./project-scanner.sh [project_path]

set -e

PROJECT_PATH=${1:-.}

show_help() {
    echo "用法: $0 [project_path]"
    echo ""
    echo "扫描项目结构，识别语言和模块划分"
    echo ""
    echo "示例:"
    echo "  $0              # 扫描当前目录"
    echo "  $0 /path/to/project  # 扫描指定目录"
    echo ""
    echo "输出: 项目语言、框架和模块信息"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

if [ ! -d "$PROJECT_PATH" ]; then
    echo "错误：目录不存在: $PROJECT_PATH" >&2
    exit 1
fi

cd "$PROJECT_PATH"

echo "=== 项目结构扫描 ==="
echo "路径: $(pwd)"
echo ""

# ─────────────────────────────────────────────
# 1. 检测编程语言和框架
# ─────────────────────────────────────────────
echo "=== 语言与框架检测 ==="

LANG=""
FRAMEWORK=""

if [ -f "go.mod" ]; then
    LANG="Go"
    MODULE_NAME=$(head -1 go.mod | awk '{print $2}')
    echo "语言: Go"
    echo "模块: $MODULE_NAME"
    # 检测 Go 框架
    if grep -q "gin-gonic/gin" go.mod 2>/dev/null; then
        FRAMEWORK="Gin"
    elif grep -q "gorilla/mux" go.mod 2>/dev/null; then
        FRAMEWORK="Gorilla Mux"
    elif grep -q "go-chi/chi" go.mod 2>/dev/null; then
        FRAMEWORK="Chi"
    elif grep -q "labstack/echo" go.mod 2>/dev/null; then
        FRAMEWORK="Echo"
    fi
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
    LANG="Python"
    echo "语言: Python"
    # 检测 Python 框架
    if [ -f "requirements.txt" ]; then
        if grep -qi "flask" requirements.txt 2>/dev/null; then
            FRAMEWORK="Flask"
        elif grep -qi "fastapi" requirements.txt 2>/dev/null; then
            FRAMEWORK="FastAPI"
        elif grep -qi "django" requirements.txt 2>/dev/null; then
            FRAMEWORK="Django"
        fi
    fi
    if [ -z "$FRAMEWORK" ] && [ -f "pyproject.toml" ]; then
        if grep -qi "flask" pyproject.toml 2>/dev/null; then
            FRAMEWORK="Flask"
        elif grep -qi "fastapi" pyproject.toml 2>/dev/null; then
            FRAMEWORK="FastAPI"
        elif grep -qi "django" pyproject.toml 2>/dev/null; then
            FRAMEWORK="Django"
        fi
    fi
elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
    LANG="Java"
    echo "语言: Java"
    if [ -f "pom.xml" ]; then
        if grep -q "spring-boot" pom.xml 2>/dev/null; then
            FRAMEWORK="Spring Boot"
        fi
    fi
    if [ -f "build.gradle" ]; then
        if grep -q "spring-boot" build.gradle 2>/dev/null; then
            FRAMEWORK="Spring Boot"
        fi
    fi
elif [ -f "package.json" ]; then
    LANG="Node.js"
    echo "语言: Node.js / TypeScript"
    # 检测 Node 框架
    if grep -q '"next"' package.json 2>/dev/null; then
        FRAMEWORK="Next.js"
    elif grep -q '"express"' package.json 2>/dev/null; then
        FRAMEWORK="Express"
    elif grep -q '"fastify"' package.json 2>/dev/null; then
        FRAMEWORK="Fastify"
    elif grep -q '"nestjs"' package.json 2>/dev/null || grep -q '"@nestjs/core"' package.json 2>/dev/null; then
        FRAMEWORK="NestJS"
    fi
elif [ -f "Cargo.toml" ]; then
    LANG="Rust"
    echo "语言: Rust"
fi

if [ -n "$FRAMEWORK" ]; then
    echo "框架: $FRAMEWORK"
fi

echo ""

# ─────────────────────────────────────────────
# 2. 检测数据库
# ─────────────────────────────────────────────
echo "=== 数据库检测 ==="

DB=""
if [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ]; then
    COMPOSE_FILE=$(ls docker-compose.y*ml 2>/dev/null | head -1)
    if grep -q "postgres" "$COMPOSE_FILE" 2>/dev/null; then
        DB="PostgreSQL"
    elif grep -q "mysql" "$COMPOSE_FILE" 2>/dev/null; then
        DB="MySQL"
    elif grep -q "mongo" "$COMPOSE_FILE" 2>/dev/null; then
        DB="MongoDB"
    elif grep -q "redis" "$COMPOSE_FILE" 2>/dev/null; then
        DB="${DB:+$DB + }Redis"
    fi
fi

# 从代码中检测
if [ -z "$DB" ]; then
    if find . -name "*.go" -maxdepth 5 -exec grep -l "postgres\|pgx\|pq" {} + 2>/dev/null | head -1 | grep -q .; then
        DB="PostgreSQL"
    elif find . -name "*.py" -maxdepth 5 -exec grep -l "psycopg\|asyncpg\|postgresql" {} + 2>/dev/null | head -1 | grep -q .; then
        DB="PostgreSQL"
    fi
fi

if [ -n "$DB" ]; then
    echo "数据库: $DB"
else
    echo "数据库: 未检测到"
fi

echo ""

# ─────────────────────────────────────────────
# 3. 识别模块结构
# ─────────────────────────────────────────────
echo "=== 模块识别 ==="

identify_modules() {
    local lang=$1
    local modules=()

    case "$lang" in
        Go)
            # Go: internal/ 或 pkg/ 下的子目录
            if [ -d "internal" ]; then
                echo "策略: internal/ 子目录"
                for dir in internal/*/; do
                    if [ -d "$dir" ]; then
                        mod_name=$(basename "$dir")
                        file_count=$(find "$dir" -name "*.go" | wc -l)
                        echo "  [$mod_name] $dir ($file_count .go files)"
                    fi
                done
            elif [ -d "pkg" ]; then
                echo "策略: pkg/ 子目录"
                for dir in pkg/*/; do
                    if [ -d "$dir" ]; then
                        mod_name=$(basename "$dir")
                        file_count=$(find "$dir" -name "*.go" | wc -l)
                        echo "  [$mod_name] $dir ($file_count .go files)"
                    fi
                done
            fi
            ;;
        Python)
            if [ "$FRAMEWORK" = "Django" ]; then
                echo "策略: Django apps"
                find . -name "apps.py" -maxdepth 3 | while read -r app; do
                    app_dir=$(dirname "$app")
                    mod_name=$(basename "$app_dir")
                    file_count=$(find "$app_dir" -name "*.py" | wc -l)
                    echo "  [$mod_name] $app_dir ($file_count .py files)"
                done
            else
                echo "策略: 顶层 Python 包"
                for dir in */; do
                    if [ -f "${dir}__init__.py" ] && [ "$dir" != "tests/" ] && [ "$dir" != "venv/" ] && [ "$dir" != ".venv/" ]; then
                        mod_name=$(basename "$dir")
                        file_count=$(find "$dir" -name "*.py" | wc -l)
                        echo "  [$mod_name] $dir ($file_count .py files)"
                    fi
                done
            fi
            ;;
        Java)
            echo "策略: Java 源码包"
            if [ -d "src/main/java" ]; then
                find src/main/java -mindepth 3 -maxdepth 4 -type d | while read -r dir; do
                    mod_name=$(basename "$dir")
                    file_count=$(find "$dir" -name "*.java" -maxdepth 1 | wc -l)
                    if [ "$file_count" -gt 0 ]; then
                        echo "  [$mod_name] $dir ($file_count .java files)"
                    fi
                done
            fi
            ;;
        "Node.js")
            echo "策略: src/ 子目录"
            if [ -d "src" ]; then
                for dir in src/*/; do
                    if [ -d "$dir" ]; then
                        mod_name=$(basename "$dir")
                        file_count=$(find "$dir" \( -name "*.ts" -o -name "*.js" \) | wc -l)
                        echo "  [$mod_name] $dir ($file_count files)"
                    fi
                done
            fi
            ;;
    esac
}

identify_modules "$LANG"

echo ""

# ─────────────────────────────────────────────
# 4. 模块文件统计
# ─────────────────────────────────────────────
echo "=== 模块文件统计 ==="
echo "（各模块作为业务单元整体分析，不按技术层拆分）"

echo ""

# ─────────────────────────────────────────────
# 5. 输出 JSON 摘要
# ─────────────────────────────────────────────
echo "=== JSON 摘要 ==="
cat <<EOF
{
  "language": "${LANG:-unknown}",
  "framework": "${FRAMEWORK:-unknown}",
  "database": "${DB:-unknown}",
  "project_path": "$(pwd)"
}
EOF
