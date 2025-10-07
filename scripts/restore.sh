#!/bin/bash

# 恢复日历记事本数据

set -e

# 配置
BACKUP_DIR="./backups"
CONTAINER_NAME="calendar-notebook"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 检查备份目录
if [ ! -d "$BACKUP_DIR" ]; then
    log_error "备份目录不存在: $BACKUP_DIR"
    exit 1
fi

# 列出可用备份
log_info "可用备份文件:"
echo ""
ls -la "$BACKUP_DIR"/*.json 2>/dev/null || {
    log_error "没有找到备份文件"
    exit 1
}
echo ""

# 提示用户选择备份文件
if [ -z "$1" ]; then
    read -p "请输入要恢复的备份文件名: " backup_file
else
    backup_file="$1"
fi

# 检查备份文件是否存在
if [ ! -f "$BACKUP_DIR/$backup_file" ]; then
    log_error "备份文件不存在: $BACKUP_DIR/$backup_file"
    exit 1
fi

# 确认恢复
log_warning "恢复操作将覆盖当前所有数据！"
read -p "确认要恢复数据吗？(输入 'YES' 继续): " confirm

if [ "$confirm" != "YES" ]; then
    log_info "恢复操作已取消"
    exit 0
fi

# 停止服务
log_info "停止服务..."
./scripts/stop.sh

# 恢复数据
log_info "恢复数据..."
if [ -f "data/data.json" ]; then
    # 创建当前数据的备份
    cp "data/data.json" "data/data.json.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "当前数据已备份为: data/data.json.backup.$(date +%Y%m%d_%H%M%S)"
fi

# 复制备份文件
cp "$BACKUP_DIR/$backup_file" "data/data.json"

# 启动服务
log_info "启动服务..."
./scripts/start.sh

log_success "数据恢复完成！"
echo "恢复的备份文件: $backup_file"
echo "如果出现问题，可以使用备份文件: data/data.json.backup.$(date +%Y%m%d_%H%M%S)"