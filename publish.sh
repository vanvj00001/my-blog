#!/usr/bin/env bash
set -euo pipefail

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}✓ $1${NC}"; }
echo_blue() { echo -e "${BLUE}→ $1${NC}"; }
echo_error() { echo -e "${RED}✗ $1${NC}"; }

echo_blue "📝 发布新文章"
echo ""

# 检查 git 状态
if ! git diff --quiet; then
  echo_blue "检测到未暂存的更改，正在暂存..."
fi

git add content/

# 检查是否有改动
if ! git diff --cached --quiet; then
  echo ""
  echo_blue "待发布文件："
  git diff --cached --name-only
  echo ""

  # 获取提交信息
  read -p "$(echo -e ${BLUE}→${NC} 输入提交描述 (默认: Add new posts): " COMMIT_MSG
  COMMIT_MSG=${COMMIT_MSG:-"Add new posts"}

  echo ""
  echo_blue "提交并推送中..."
  git commit -m "$COMMIT_MSG"
  git push origin main

  echo ""
  echo_info "发布成功！"
  echo_blue "GitHub Actions 正在自动部署..."
  echo_blue "访问: https://github.com/vanvj00001/my-blog/actions 查看进度"
  echo ""
else
  echo_error "没有检测到新的内容更改"
  exit 1
fi
