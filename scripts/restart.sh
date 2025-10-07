#!/bin/bash

# 重启日历记事本服务

set -e

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 停止服务
log_info "停止服务..."
./scripts/stop.sh

# 启动服务
log_info "启动服务..."
./scripts/start.sh

log_success "服务重启完成"