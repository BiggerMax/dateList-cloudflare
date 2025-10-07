#!/bin/bash

# 备份日历记事本数据

set -e

# 配置
BACKUP_DIR="./backups"
CONTAINER_NAME="calendar-notebook"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="calendar_backup_${DATE}.json"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 创建备份目录
mkdir -p "$BACKUP_DIR"

# 检查容器是否运行
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    log_warning "容器未运行，尝试从宿主机备份..."
    
    # 从宿主机备份
    if [ -f "data/data.json" ]; then
        cp "data/data.json" "$BACKUP_DIR/$BACKUP_FILE"
        log_success "备份完成: $BACKUP_DIR/$BACKUP_FILE"
    else
        echo "错误: 数据文件不存在"
        exit 1
    fi
else
    # 从容器内备份
    log_info "从容器内备份数据..."
    
    # 在容器内创建备份
    docker exec "$CONTAINER_NAME" sh -c "cd /app && node -e \"
        const fs = require('fs');
        const data = fs.readFileSync('/app/data/data.json', 'utf8');
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        fs.writeFileSync('/app/backups/backup_' + timestamp + '.json', data);
        console.log('备份文件: backup_' + timestamp + '.json');
    \""
    
    # 复制备份文件到宿主机
    docker cp "$CONTAINER_NAME:/app/backups/" "$BACKUP_DIR/"
    
    log_success "备份完成，文件保存在: $BACKUP_DIR/"
fi

# 清理旧备份（保留最近7天）
log_info "清理旧备份..."
find "$BACKUP_DIR" -name "calendar_backup_*.json" -mtime +7 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "backup_*.json" -mtime +7 -delete 2>/dev/null || true

log_success "备份清理完成"