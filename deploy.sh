#!/usr/bin/env bash
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}✓ $1${NC}"; }
echo_error() { echo -e "${RED}✗ $1${NC}"; }
echo_blue() { echo -e "${BLUE}→ $1${NC}"; }

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/public"
REPO_URL="https://github.com/vanvj00001/my-blog.git"
DEPLOY_BRANCH="gh-pages"

echo_blue "🚀 Hugo 博客部署脚本"
echo ""

# 检查依赖
echo_blue "检查依赖..."
for cmd in hugo git; do
  if ! command -v "$cmd" &>/dev/null; then
    echo_error "$cmd 未安装"
    exit 1
  fi
done
echo_info "所有依赖就绪"
echo ""

# 清理旧版本
echo_blue "清理旧版本..."
rm -rf "$BUILD_DIR"
echo_info "清理完毕"
echo ""

# 构建 Hugo 站点
echo_blue "构建 Hugo 站点..."
if hugo --minify --source "$SCRIPT_DIR"; then
  echo_info "构建成功"
else
  echo_error "Hugo 构建失败"
  exit 1
fi
echo ""

# 检查 gh-pages 分支是否存在
echo_blue "准备发布到 GitHub Pages..."
if ! git rev-parse --verify "$DEPLOY_BRANCH" &>/dev/null; then
  echo_blue "本地检出 $DEPLOY_BRANCH 分支..."
  git fetch origin "$DEPLOY_BRANCH"
  git checkout -b "$DEPLOY_BRANCH" "origin/$DEPLOY_BRANCH"
fi

# 切换到 gh-pages 分支
git checkout "$DEPLOY_BRANCH"
git pull origin "$DEPLOY_BRANCH" --ff-only 2>/dev/null || true

# 清空并复制新文件
echo_blue "同步构建文件..."
git rm -rf . 2>/dev/null || find . -maxdepth 1 -not -name '.git' -type f -delete && find . -maxdepth 1 -not -name '.git' -type d -exec rm -rf {} + 2>/dev/null || true
cp -r "$BUILD_DIR"/* ./
touch .nojekyll

# 提交和推送
echo_blue "提交更改..."
git add -A

if git diff --cached --quiet; then
  echo_info "没有新的更改"
else
  git commit -m "Deploy: $(date +'%Y-%m-%d %H:%M:%S')"

  echo_blue "推送到 GitHub..."
  if git push origin "$DEPLOY_BRANCH"; then
    echo_info "推送成功"
  else
    echo_error "推送失败，请检查网络和权限"
    exit 1
  fi
fi

# 切回 main 分支
git checkout main
cd "$SCRIPT_DIR"
echo ""
echo_info "部署完成！"
echo_blue "访问: https://vanvj00001.github.io/my-blog/"
