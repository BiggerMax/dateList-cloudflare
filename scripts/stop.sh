#!/bin/bash

# 停止日历记事本服务

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${RED}[WARNING]${NC} $1"
}

# 检查服务是否运行
if ! docker-compose ps | grep -q "Up"; then
    log_warning "服务未运行"
    exit 0
fi

# 停止服务
log_info "停止日历记事本服务..."
docker-compose down

# 检查服务状态
if docker-compose ps | grep -q "Up"; then
    echo "错误: 服务停止失败"
    exit 1
else
    log_success "服务已停止"
fi