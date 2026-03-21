#!/bin/bash
# Diff Parser for spec-sync
# 解析 git diff，提取变更信息用于 spec 同步

set -e

BASE_BRANCH=${1:-main}
HEAD_BRANCH=${2:-HEAD}

show_help() {
    echo "用法: $0 [base_branch] [head_branch]"
    echo ""
    echo "示例:"
    echo "  $0                  # 比较 main..HEAD"
    echo "  $0 main feature/x   # 比较 main..feature/x"
    echo "  $0 v1.0 v1.1        # 比较 tag v1.0..v1.1"
    echo ""
    echo "输出: JSON 格式的变更摘要"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# 检查 git 仓库
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "错误：不是 git 仓库" >&2
    exit 1
fi

# 获取统计信息
echo "=== 变更统计 ==="
git diff "$BASE_BRANCH...$HEAD_BRANCH" --stat

echo ""
echo "=== 变更文件列表 ==="

# 按模块分组显示变更文件
git diff "$BASE_BRANCH...$HEAD_BRANCH" --name-only | while read -r file; do
    # 尝试提取模块名
    if [[ "$file" =~ internal/([^/]+)/ ]]; then
        module="${BASH_REMATCH[1]}"
        echo "[$module] $file"
    elif [[ "$file" =~ pkg/([^/]+)/ ]]; then
        module="pkg:${BASH_REMATCH[1]}"
        echo "[$module] $file"
    else
        echo "[other] $file"
    fi
done

echo ""
echo "=== API 变更检测 ==="
# 检测新增的路由/处理器
git diff "$BASE_BRANCH...$HEAD_BRANCH" | grep -E "^\+.*(GET|POST|PUT|DELETE|PATCH).*/api/" || echo "无明显 API 路由变更"

echo ""
echo "=== 模型变更检测 ==="
# 检测模型/实体变更
git diff "$BASE_BRANCH...$HEAD_BRANCH" --name-only | grep -E "(model|entity|schema)" || echo "无模型文件变更"
