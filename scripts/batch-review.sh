#!/usr/bin/env bash
# ============================================================
# batch-review.sh — 批量评审 inputs/ 下所有 PDF 文件
# 用法: bash scripts/batch-review.sh
# ============================================================

set -euo pipefail

# ---------- 配置 ----------
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INPUTS_DIR="$PROJECT_ROOT/inputs"
OUTPUTS_DIR="$PROJECT_ROOT/outputs"
SCRIPT_DIR="$PROJECT_ROOT/scripts"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$OUTPUTS_DIR/batch_log_${TIMESTAMP}.txt"

echo "╔══════════════════════════════════════════╗"
echo "║     📋 正大杯评审助手 — 批量评审         ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ---------- 扫描 PDF 文件 ----------
PDF_FILES=()
while IFS= read -r -d '' file; do
    PDF_FILES+=("$file")
done < <(find "$INPUTS_DIR" -maxdepth 1 -name "*.pdf" -print0 | sort -z)

TOTAL=${#PDF_FILES[@]}

if [ "$TOTAL" -eq 0 ]; then
    echo "❌ 未在 inputs/ 目录下找到 PDF 文件"
    echo "   请将待评审的 PDF 文件放入: $INPUTS_DIR/"
    exit 1
fi

echo "📂 发现 $TOTAL 个 PDF 文件待评审："
for i in "${!PDF_FILES[@]}"; do
    echo "   $((i+1)). $(basename "${PDF_FILES[$i]}")"
done
echo ""

# ---------- 确认 ----------
read -p "🚀 是否开始批量评审？(y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "已取消。"
    exit 0
fi

echo ""
echo "📝 评审日志: $LOG_FILE"
echo "────────────────────────────────────────────"
echo ""

# ---------- 初始化日志 ----------
{
    echo "正大杯批量评审日志"
    echo "开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "文件总数: $TOTAL"
    echo "========================================"
} > "$LOG_FILE"

# ---------- 逐个评审 ----------
SUCCESS=0
FAIL=0

for i in "${!PDF_FILES[@]}"; do
    FILE="${PDF_FILES[$i]}"
    BASENAME=$(basename "$FILE")
    CURRENT=$((i+1))

    echo "[$CURRENT/$TOTAL] 🔍 正在评审: $BASENAME"
    echo "" >> "$LOG_FILE"
    echo "[$CURRENT/$TOTAL] $BASENAME" >> "$LOG_FILE"
    echo "  开始: $(date '+%H:%M:%S')" >> "$LOG_FILE"

    # 调用单文件评审脚本
    if bash "$SCRIPT_DIR/review.sh" "$FILE" >> "$LOG_FILE" 2>&1; then
        echo "[$CURRENT/$TOTAL] ✅ 完成: $BASENAME"
        echo "  状态: 成功" >> "$LOG_FILE"
        SUCCESS=$((SUCCESS+1))
    else
        echo "[$CURRENT/$TOTAL] ❌ 失败: $BASENAME"
        echo "  状态: 失败" >> "$LOG_FILE"
        FAIL=$((FAIL+1))
    fi

    echo "  结束: $(date '+%H:%M:%S')" >> "$LOG_FILE"

    # 文件间暂停，避免 API 限流
    if [ $CURRENT -lt $TOTAL ]; then
        echo "   ⏳ 等待 5 秒后继续..."
        sleep 5
    fi
done

# ---------- 汇总 ----------
echo ""
echo "════════════════════════════════════════════"
echo "📊 批量评审完成"
echo ""
echo "   ✅ 成功: $SUCCESS / $TOTAL"
echo "   ❌ 失败: $FAIL / $TOTAL"
echo "   📁 报告目录: $OUTPUTS_DIR/"
echo "   📝 完整日志: $LOG_FILE"
echo "   ⏰ 完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════"

# 写入日志汇总
{
    echo ""
    echo "========================================"
    echo "汇总"
    echo "  成功: $SUCCESS"
    echo "  失败: $FAIL"
    echo "  完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
} >> "$LOG_FILE"

# 如果有失败的，返回非零退出码
[ "$FAIL" -eq 0 ]
