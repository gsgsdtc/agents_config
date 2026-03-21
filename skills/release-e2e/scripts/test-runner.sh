#!/bin/bash
# Test Runner for release-e2e
# 解析 main-flows.md 并执行指定主流程测试
# 用法: ./test-runner.sh <main-flows.md> <flow-id|all> <base-url> [priority-filter]

set -e

MAIN_FLOWS_FILE=${1:-"docs/spec/main-flows.md"}
FLOW_ID=${2:-"all"}
BASE_URL=${3:-"http://localhost:8080"}
PRIORITY_FILTER=${4:-"P0,P1"}
REPORT_DIR="docs/reports"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="${REPORT_DIR}/release-e2e-${TIMESTAMP}.md"

show_help() {
    echo "用法: $0 <main-flows.md> <flow-id|all> <base-url> [priority-filter]"
    echo ""
    echo "参数:"
    echo "  main-flows.md   主流程定义文件路径 (默认: docs/spec/main-flows.md)"
    echo "  flow-id         指定流程 ID 或 'all' (默认: all)"
    echo "  base-url        目标环境 URL (默认: http://localhost:8080)"
    echo "  priority-filter P0,P1,P2 (默认: P0,P1)"
    echo ""
    echo "示例:"
    echo "  $0 docs/spec/main-flows.md all https://staging.example.com"
    echo "  $0 docs/spec/main-flows.md MF-001 http://localhost:8080"
    echo "  $0 docs/spec/main-flows.md all https://staging.example.com P0"
    echo ""
    echo "输出: Markdown 格式的验证报告"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# ─────────────────────────────────────────────
# 验证输入
# ─────────────────────────────────────────────
if [ ! -f "$MAIN_FLOWS_FILE" ]; then
    echo "错误：主流程文件不存在: $MAIN_FLOWS_FILE" >&2
    echo "请先创建 main-flows.md，模板见: docs/template-main-flows.md" >&2
    exit 1
fi

# 创建报告目录
mkdir -p "$REPORT_DIR"

# ─────────────────────────────────────────────
# 解析 main-flows.md，提取流程列表
# ─────────────────────────────────────────────
echo "=== Release E2E Test Runner ==="
echo "目标环境: $BASE_URL"
echo "主流程文件: $MAIN_FLOWS_FILE"
echo "优先级筛选: $PRIORITY_FILTER"
echo "报告输出: $REPORT_FILE"
echo ""

# 提取流程 ID、名称和优先级（从 markdown 表格中）
# 格式: | MF-001 | 用户注册→登录→首页 | P0 | API+UI | ... |
extract_flows() {
    grep -E '^\| *MF-[0-9]+' "$MAIN_FLOWS_FILE" | while IFS='|' read -r _ id name priority type _rest; do
        id=$(echo "$id" | xargs)
        name=$(echo "$name" | xargs)
        priority=$(echo "$priority" | xargs)
        type=$(echo "$type" | xargs)

        # 应用优先级过滤
        if echo "$PRIORITY_FILTER" | grep -q "$priority"; then
            echo "${id}|${name}|${priority}|${type}"
        fi
    done
}

FLOWS=$(extract_flows)

if [ -z "$FLOWS" ]; then
    echo "警告：未找到匹配的主流程（优先级: $PRIORITY_FILTER）" >&2
    exit 0
fi

# 统计
TOTAL_FLOWS=$(echo "$FLOWS" | wc -l)
PASSED=0
FAILED=0
PARTIAL=0

echo "找到 $TOTAL_FLOWS 个匹配的主流程"
echo ""

# ─────────────────────────────────────────────
# 初始化报告
# ─────────────────────────────────────────────
cat > "$REPORT_FILE" << EOF
# Release E2E 验证报告

> 执行时间：$(date '+%Y-%m-%d %H:%M:%S')
> 目标环境：$BASE_URL
> 优先级：$PRIORITY_FILTER
> 执行人：Claude

## 执行摘要

| 统计 | 数值 |
|------|------|
| 总流程数 | $TOTAL_FLOWS |
| ✅ 通过 | 待更新 |
| ❌ 失败 | 待更新 |
| 总耗时 | 待更新 |

## 详细结果

EOF

# ─────────────────────────────────────────────
# 逐个执行流程
# ─────────────────────────────────────────────
START_TIME=$(date +%s)

execute_api_step() {
    local method=$1
    local endpoint=$2
    local data=$3
    local expected_status=${4:-200}

    local url="${BASE_URL}${endpoint}"
    local start=$(date +%s%N)

    if [ -n "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "Content-Type: application/json" \
            -H "${AUTH_HEADER:-}" \
            -d "$data" 2>/dev/null || echo -e "\n000")
    else
        response=$(curl -s -w "\n%{http_code}" -X "$method" "$url" \
            -H "${AUTH_HEADER:-}" 2>/dev/null || echo -e "\n000")
    fi

    local end=$(date +%s%N)
    local elapsed=$(( (end - start) / 1000000 ))

    local status_code=$(echo "$response" | tail -1)
    local body=$(echo "$response" | sed '$d')

    if [ "$status_code" = "$expected_status" ]; then
        echo "PASS|${elapsed}ms|$status_code|$body"
    else
        echo "FAIL|${elapsed}ms|$status_code|$body"
    fi
}

echo "$FLOWS" | while IFS='|' read -r flow_id flow_name flow_priority flow_type; do
    # 如果指定了特定 flow-id，跳过不匹配的
    if [ "$FLOW_ID" != "all" ] && [ "$flow_id" != "$FLOW_ID" ]; then
        continue
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "执行: $flow_id - $flow_name ($flow_priority, $flow_type)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    flow_start=$(date +%s)
    flow_result="PASS"

    # 写入报告
    cat >> "$REPORT_FILE" << EOF
### $flow_id: $flow_name ($flow_priority)

| 步骤 | 操作 | 结果 | 耗时 |
|------|------|------|------|
EOF

    # 提取该流程的步骤（从流程详情部分）
    # 查找 ### MF-xxx 到下一个 ### 之间的步骤表格
    in_flow=false
    step_count=0

    while IFS= read -r line; do
        if echo "$line" | grep -q "^### *$flow_id"; then
            in_flow=true
            continue
        fi
        if $in_flow && echo "$line" | grep -q "^### "; then
            break
        fi
        if $in_flow; then
            # 解析步骤行: | 1 | POST /api/xxx | ... |
            if echo "$line" | grep -qE '^\| *[0-9]+ *\|'; then
                step_count=$((step_count + 1))
                step_info=$(echo "$line" | sed 's/^| *//;s/ *|$//' | awk -F'|' '{print $2}' | xargs)
                echo "  Step $step_count: $step_info"

                # 基础连通性测试
                if echo "$step_info" | grep -qE '(GET|POST|PUT|DELETE|PATCH)'; then
                    method=$(echo "$step_info" | awk '{print $1}')
                    endpoint=$(echo "$step_info" | awk '{print $2}')

                    if [ -n "$method" ] && [ -n "$endpoint" ]; then
                        result=$(execute_api_step "$method" "$endpoint" "" "")
                        status=$(echo "$result" | cut -d'|' -f1)
                        elapsed=$(echo "$result" | cut -d'|' -f2)
                        http_code=$(echo "$result" | cut -d'|' -f3)

                        if [ "$status" = "PASS" ]; then
                            echo "    ✅ $http_code ($elapsed)"
                            echo "| $step_count | $step_info | ✅ PASS ($http_code) | $elapsed |" >> "$REPORT_FILE"
                        else
                            echo "    ❌ $http_code ($elapsed)"
                            echo "| $step_count | $step_info | ❌ FAIL ($http_code) | $elapsed |" >> "$REPORT_FILE"
                            flow_result="FAIL"
                        fi
                    fi
                else
                    echo "    ⏭️ UI 步骤 (需 agent-browser)"
                    echo "| $step_count | $step_info | ⏭️ SKIP (需 agent-browser) | - |" >> "$REPORT_FILE"
                fi
            fi
        fi
    done < "$MAIN_FLOWS_FILE"

    flow_end=$(date +%s)
    flow_elapsed=$((flow_end - flow_start))

    if [ "$step_count" -eq 0 ]; then
        echo "  (未找到可执行的步骤定义)"
        echo "| - | 未找到步骤定义 | ⚠️ | - |" >> "$REPORT_FILE"
        flow_result="SKIP"
    fi

    echo ""
    echo "  结果: $flow_result (${flow_elapsed}s)"
    echo "" >> "$REPORT_FILE"

    case "$flow_result" in
        PASS)   PASSED=$((PASSED + 1)) ;;
        FAIL)   FAILED=$((FAILED + 1)) ;;
        *)      PARTIAL=$((PARTIAL + 1)) ;;
    esac

    echo ""
done

END_TIME=$(date +%s)
TOTAL_ELAPSED=$((END_TIME - START_TIME))

# ─────────────────────────────────────────────
# 生成 GO/NO-GO 建议
# ─────────────────────────────────────────────
if [ "$FAILED" -gt 0 ]; then
    DECISION="NO-GO"
    DECISION_ICON="🔴"
else
    DECISION="GO"
    DECISION_ICON="🟢"
fi

# 更新报告摘要
cat >> "$REPORT_FILE" << EOF
## GO/NO-GO 建议

### $DECISION_ICON $DECISION

- 通过: $PASSED
- 失败: $FAILED
- 跳过: $PARTIAL
- 总耗时: ${TOTAL_ELAPSED}s

---

*报告生成时间：$(date '+%Y-%m-%d %H:%M:%S')*
EOF

# ─────────────────────────────────────────────
# 输出总结
# ─────────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Release E2E 执行完成"
echo ""
echo "  通过: $PASSED"
echo "  失败: $FAILED"
echo "  跳过: $PARTIAL"
echo "  总耗时: ${TOTAL_ELAPSED}s"
echo ""
echo "  建议: $DECISION_ICON $DECISION"
echo ""
echo "  报告: $REPORT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 返回退出码
if [ "$FAILED" -gt 0 ]; then
    exit 1
fi
exit 0
