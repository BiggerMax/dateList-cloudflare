#!/bin/bash

# 启动日历记事本服务

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

# 检查Docker服务
if ! docker info > /dev/null 2>&1; then
    echo "错误: Docker服务未运行"
    exit 1
fi

# 启动服务
log_info "启动日历记事本服务..."
docker-compose up -d

# 等待服务启动
sleep 5

# 检查服务状态
if docker-compose ps | grep -q "Up"; then
    log_success "服务启动成功"
    echo "访问地址: http://localhost:3001"
    echo "健康检查: http://localhost:3001/health"
else
    echo "错误: 服务启动失败"
    docker-compose logs
    exit 1
fi