#!/bin/bash

set -e

REPO_DIR="/Users/vanvj/my-blog"
REMOTE_URL="https://github.com/vanvj00003/my-blog"

commit_msg="${1:-deploy: $(date '+%Y-%m-%d %H:%M:%S')}"

echo "=========================================="
echo "开始部署博客到 GitHub"
echo "=========================================="

cd "$REPO_DIR"

# Clean build
echo "[1/4] 清理旧构建..."
rm -rf public resources/_gen

# Build
echo "[2/4] 构建博客..."
hugo --minify

# Add changes
echo "[3/4] 提交更改..."
git add -A
git commit -m "$commit_msg" || echo "没有更改需要提交"

# Push to gh-pages
echo "[4/4] 推送到 GitHub gh-pages..."
git push "$REMOTE_URL" gh-pages

echo "=========================================="
echo "部署完成！"
echo "博客地址：https://vanvj00003.github.io/monkvan"
echo "=========================================="
