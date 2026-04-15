#!/usr/bin/env bash
# ============================================================
# review.sh — 使用 Claude Code 对单个 PDF 进行评审
# 用法: bash scripts/review.sh inputs/项目计划书.pdf
# ============================================================

set -euo pipefail

# ---------- 配置 ----------
PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INPUTS_DIR="$PROJECT_ROOT/inputs"
OUTPUTS_DIR="$PROJECT_ROOT/outputs"
RULES_DIR="$PROJECT_ROOT/rules"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# ---------- 参数检查 ----------
if [ $# -lt 1 ]; then
    echo "❌ 用法: bash scripts/review.sh <PDF文件路径>"
    echo ""
    echo "示例:"
    echo "  bash scripts/review.sh inputs/项目计划书.pdf"
    echo "  bash scripts/review.sh /path/to/file.pdf"
    exit 1
fi

INPUT_FILE="$1"

# 如果传入的是相对路径且不带 inputs/ 前缀，尝试在 inputs/ 下查找
if [ ! -f "$INPUT_FILE" ]; then
    if [ -f "$INPUTS_DIR/$INPUT_FILE" ]; then
        INPUT_FILE="$INPUTS_DIR/$INPUT_FILE"
    else
        echo "❌ 文件不存在: $INPUT_FILE"
        echo "   请确认文件路径，或将 PDF 放入 inputs/ 目录"
        exit 1
    fi
fi

# 检查文件类型
if [[ ! "$INPUT_FILE" =~ \.pdf$ ]]; then
    echo "⚠️  警告: 文件不是 PDF 格式，评审结果可能受影响"
fi

# ---------- 生成输出文件名 ----------
BASENAME=$(basename "$INPUT_FILE" .pdf)
OUTPUT_FILE="$OUTPUTS_DIR/${BASENAME}_评审报告_${TIMESTAMP}.md"

echo "╔══════════════════════════════════════════╗"
echo "║     📋 正大杯评审助手 — 单文件评审       ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "📄 输入文件: $INPUT_FILE"
echo "📁 输出路径: $OUTPUT_FILE"
echo "⏰ 开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "🔍 正在启动 Claude Code 进行评审..."
echo "────────────────────────────────────────────"

# ---------- 调用 Claude Code ----------
claude --print \
    "请按照以下步骤对参赛作品进行评审：

1. 先完整阅读以下三个规则文件，理解评审框架：
   - $RULES_DIR/review-prompt.md（评审角色与输出格式）
   - $RULES_DIR/scoring.md（评分维度与标准）
   - $RULES_DIR/checklist.md（形式审查清单）

2. 然后阅读待评审的 PDF 文件：
   - $INPUT_FILE

3. 严格按照 review-prompt.md 中定义的输出格式，完成完整的评审报告。

4. 将评审报告以 Markdown 格式写入：
   - $OUTPUT_FILE

注意：
- 每个评分必须有原文依据
- 改进建议必须具体可操作
- 如有内容缺失，标记为 ⚠️ 并说明对评分的影响" \
    2>&1

# ---------- 检查输出 ----------
echo ""
echo "────────────────────────────────────────────"

if [ -f "$OUTPUT_FILE" ]; then
    WORD_COUNT=$(wc -c < "$OUTPUT_FILE")
    echo "✅ 评审完成！"
    echo "📄 报告文件: $OUTPUT_FILE"
    echo "📊 报告大小: ${WORD_COUNT} 字节"
    echo "⏰ 完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
else
    echo "⚠️  评审可能未成功生成报告文件"
    echo "   请检查 Claude Code 的输出信息"
fi
