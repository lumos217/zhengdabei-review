## 正大杯评审自动化 — GitHub Actions 使用指南

### 整体流程

```
推送PDF到 inputs/ → GitHub Actions自动触发 → Claude Code评审 → 评审报告上传为Artifact → 下载查看
```

---

### 第一步：项目结构

确保你的 GitHub 仓库结构如下：

```
zhengdabei-review/
├── .github/
│   └── workflows/
│       └── auto-review.yml      ← GitHub Actions 工作流（下面会创建）
├── CLAUDE.md                     ← Claude Code 项目指令
├── inputs/                       ← 推送PDF到这里触发评审
├── outputs/                      ← 评审报告输出
├── rules/
│   ├── review-prompt.md
│   ├── scoring.md
│   └── checklist.md
└── scripts/
    ├── review.sh
    └── batch-review.sh
```

---

### 第二步：创建工作流文件

在仓库中创建 `.github/workflows/auto-review.yml`，内容见下方。

---

### 第三步：配置 Secrets

在 GitHub 仓库中设置 API 密钥：

1. 进入仓库页面 → **Settings** → **Secrets and variables** → **Actions**
2. 点击 **New repository secret**
3. 添加以下 secret：
   - Name: `ANTHROPIC_API_KEY`
   - Value: 你的 Anthropic API Key（从 console.anthropic.com 获取）

---

### 第四步：使用方式

```bash
# 把待评审的PDF放入 inputs/ 目录
cp 某队伍计划书.pdf inputs/

# 推送到GitHub
git add inputs/某队伍计划书.pdf
git commit -m "添加评审: 某队伍计划书"
git push
```

推送后 GitHub Actions 会自动：
1. 检测到 inputs/ 下有新的PDF文件
2. 安装 Claude Code
3. 逐个评审每份PDF
4. 将评审报告上传为 Artifact

你可以在仓库的 **Actions** 标签页查看运行状态，完成后下载评审报告。

---

### 注意事项

- 只有 `inputs/` 目录下的 `.pdf` 文件变动才会触发工作流
- 评审报告会保留 30 天（可在 workflow 中调整）
- 每次运行会评审所有 inputs/ 下的 PDF（包括之前已有的）
- 如果只想评审新增文件，可以使用下方工作流中的 `changes-only` 模式
