#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_info() { echo -e "${GREEN}✓ $1${NC}"; }
echo_error() { echo -e "${RED}✗ $1${NC}"; }
echo_blue() { echo -e "${BLUE}→ $1${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
BUILD_DIR="${SCRIPT_DIR}/public"

echo_blue "🚀 部署脚本"
echo ""

echo_blue "同步内容..."
if [ -d "/Users/fanweijun/oldvan/content" ]; then
  cp -r /Users/fanweijun/oldvan/content/* "$SCRIPT_DIR/content/"
  echo_info "内容同步完成"
else
  echo_error "源目录不存在"
fi
echo ""

echo_blue "清理并创建目录..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
echo_info "完成"
echo ""

echo_blue "复制静态文件..."
if [ -f "$SCRIPT_DIR/static/gold.html" ]; then
    cp "$SCRIPT_DIR/static/gold.html" "$BUILD_DIR/"
fi
if [ -d "$SCRIPT_DIR/static/gold-data" ]; then
    cp -r "$SCRIPT_DIR/static/gold-data" "$BUILD_DIR/"
fi
echo_info "完成"
echo ""

if [ ! -d "$SCRIPT_DIR/themes/hugo-book/.git" ]; then
  echo_blue "主题缺失，正在下载 hugo-book..."
  rm -rf "$SCRIPT_DIR/themes/hugo-book"
  mkdir -p "$SCRIPT_DIR/themes"
  git clone https://github.com/alex-shpak/hugo-book.git "$SCRIPT_DIR/themes/hugo-book"
  echo_info "主题下载完成"
  echo ""
fi

echo_blue "构建 Hugo 站点..."
hugo --minify
echo_info "完成"
echo ""

echo_blue "同步到 GitHub..."
git checkout main 2>/dev/null || git checkout -b main
git pull origin main --ff-only 2>/dev/null || true

find . -maxdepth 1 -not -name '.git' -not -name 'public' -not -name 'hugo.toml' -not -name 'deploy.sh' -not -name 'go.mod' -not -name 'go.sum' -not -name '.gitignore' -not -name 'README.md' -not -name 'LICENSE' -type f -exec rm -f {} +
find . -maxdepth 1 -not -name '.git' -not -name 'public' -not -name '.' -not -name 'content' -not -name 'themes' -not -name 'static' -not -name 'assets' -not -name 'resources' -not -name '.github' -type d -exec rm -rf {} + 2>/dev/null || true

cp -r "$BUILD_DIR"/* ./
touch .nojekyll

git add -A
if git diff --cached --quiet; then
    echo_info "没有新内容"
else
    git commit -m "Deploy: $(date +'%Y-%m-%d %H:%M:%S')"
    git push origin main
fi

echo ""
echo_info "完成！"
echo_blue "访问: https://vanvj00001.github.io/my-blog/"
