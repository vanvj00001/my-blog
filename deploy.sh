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
echo_warn() { echo -e "${YELLOW}⚠ $1${NC}"; }
echo_blue() { echo -e "${BLUE}→ $1${NC}"; }

# 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/vanvj00001/my-blog.git"
DEPLOY_BRANCH="gh-pages"

# 构建目录放在 /tmp（repo 外，git checkout 不会影响）
BUILD_DIR="/tmp/my-blog-deploy"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

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

# 确保 submodule 已初始化（必须在构建前）
echo_blue "初始化主题..."
cd "$SCRIPT_DIR"
if [ -f ".gitmodules" ]; then
    git submodule update --init --recursive 2>&1 | sed 's/^/  /'
fi
echo_info "主题就绪"
echo ""

# 备份静态文件
echo_blue "备份静态文件..."
BACKUP_DIR="${SCRIPT_DIR}/tmp/backup-$(date +%Y%m%d%H%M%S)"
mkdir -p "$BACKUP_DIR"
if [ -f "$SCRIPT_DIR/static/gold.html" ]; then
    cp "$SCRIPT_DIR/static/gold.html" "$BACKUP_DIR/"
fi
if [ -d "$SCRIPT_DIR/static/gold-data" ]; then
    cp -r "$SCRIPT_DIR/static/gold-data" "$BACKUP_DIR/"
fi
echo_info "静态文件备份完成"
echo ""

# 构建 Hugo（输出到 BUILD_DIR，不污染源目录）
echo_blue "构建 Hugo 站点..."
hugo --minify --source "$SCRIPT_DIR" --destination "$BUILD_DIR" 2>&1 | sed 's/^/  /'
echo_info "构建完成"
echo ""

# 恢复静态文件到构建目录
echo_blue "恢复静态文件..."
if [ -f "$BACKUP_DIR/gold.html" ]; then
    cp "$BACKUP_DIR/gold.html" "$BUILD_DIR/"
fi
if [ -d "$BACKUP_DIR/gold-data" ]; then
    cp -r "$BACKUP_DIR/gold-data" "$BUILD_DIR/"
fi
echo_info "静态文件恢复完成"
echo ""

# 发布到 gh-pages
echo_blue "准备发布到 GitHub Pages..."
cd "$SCRIPT_DIR"

# 检查 gh-pages 分支是否存在
if ! git rev-parse --verify "$DEPLOY_BRANCH" &>/dev/null; then
  echo_blue "本地检出 $DEPLOY_BRANCH 分支..."
  git fetch origin "$DEPLOY_BRANCH"
  git checkout -b "$DEPLOY_BRANCH" "origin/$DEPLOY_BRANCH"
fi

# 强制 reset 到远程 gh-pages（忽略本地所有修改）
git fetch origin "$DEPLOY_BRANCH"
git reset --hard "origin/$DEPLOY_BRANCH"

# 清理旧文件（不删除 .git 目录）
echo_blue "同步构建文件..."
find . -maxdepth 1 -not -name '.git' -type f -exec rm -f {} +
find . -maxdepth 1 -not -name '.git' -not -name '.' -type d -exec rm -rf {} + 2>/dev/null || true

# 从外部 BUILD_DIR 复制文件（不怕 git checkout）
if [ -d "$BUILD_DIR" ] && [ -n "$(ls -A "$BUILD_DIR")" ]; then
  cp -r "$BUILD_DIR"/* .
  echo_info "文件同步完成"
else
  echo_error "构建目录为空或不存在"
  rm -rf "$BUILD_DIR"
  exit 1
fi

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
    rm -rf "$BUILD_DIR"
    exit 1
  fi
fi

# 切回 main 分支
git checkout main
cd "$SCRIPT_DIR"
rm -rf "$BUILD_DIR"
echo ""
echo_info "部署完成！"
echo_blue "访问: https://vanvj00001.github.io/my-blog/"