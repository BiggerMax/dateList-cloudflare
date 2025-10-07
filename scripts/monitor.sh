#!/bin/bash

# 日历记事本监控脚本

set -e

# 配置
CONTAINER_NAME="calendar-notebook"
SERVICE_URL="http://localhost:3001"
HEALTH_URL="$SERVICE_URL/health"
LOG_FILE="./logs/monitor.log"

# 颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "$LOG_FILE"
}

# 创建日志目录
mkdir -p "$(dirname "$LOG_FILE")"

# 检查Docker服务
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        log_error "Docker服务未运行"
        return 1
    fi
    return 0
}

# 检查容器状态
check_container() {
    if ! docker ps | grep -q "$CONTAINER_NAME"; then
        log_error "容器 $CONTAINER_NAME 未运行"
        return 1
    fi
    return 0
}

# 检查健康状态
check_health() {
    if curl -f "$HEALTH_URL" > /dev/null 2>&1; then
        return 0
    else
        log_error "健康检查失败: $HEALTH_URL"
        return 1
    fi
}

# 检查资源使用情况
check_resources() {
    log_info "检查资源使用情况..."
    
    # 获取容器资源使用情况
    if docker stats "$CONTAINER_NAME" --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" 2>/dev/null; then
        log_success "资源使用情况检查完成"
    else
        log_warning "无法获取资源使用情况"
    fi
}

# 检查日志错误
check_logs() {
    log_info "检查应用日志..."
    
    # 检查最近100行日志中的错误
    if docker-compose logs --tail=100 | grep -i "error\|exception\|failed" | head -10; then
        log_warning "发现错误日志，请检查应用日志"
    else
        log_success "未发现明显错误"
    fi
}

# 显示服务状态
show_status() {
    echo "=============================================="
    echo "🗓️  日历记事本服务状态"
    echo "=============================================="
    echo ""
    
    # 容器状态
    echo "📦 容器状态:"
    docker-compose ps
    echo ""
    
    # 资源使用
    echo "💾 资源使用:"
    docker stats "$CONTAINER_NAME" --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "无法获取资源信息"
    echo ""
    
    # 健康状态
    echo "🔍 健康状态:"
    if curl -s "$HEALTH_URL" | jq . 2>/dev/null; then
        log_success "健康检查通过"
    else
        log_error "健康检查失败"
    fi
    echo ""
    
    # 数据文件信息
    echo "📁 数据文件:"
    if [ -f "data/data.json" ]; then
        echo "数据文件大小: $(du -h data/data.json | cut -f1)"
        echo "最后修改: $(stat -f %Sm data/data.json 2>/dev/null || stat -c %y data/data.json 2>/dev/null)"
    else
        echo "数据文件不存在"
    fi
    echo ""
    
    # 备份文件
    echo "💿 备份文件:"
    if [ -d "backups" ]; then
        backup_count=$(find backups -name "*.json" | wc -l)
        echo "备份文件数量: $backup_count"
        if [ $backup_count -gt 0 ]; then
            echo "最新备份: $(ls -t backups/*.json | head -1 | xargs basename)"
        fi
    else
        echo "备份目录不存在"
    fi
    echo ""
}

# 主监控函数
monitor() {
    log_info "开始监控日历记事本服务..."
    
    check_docker
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    check_container
    if [ $? -ne 0 ]; then
        log_error "容器未运行，尝试启动..."
        ./scripts/start.sh
        sleep 10
        check_container
        if [ $? -ne 0 ]; then
            log_error "容器启动失败"
            exit 1
        fi
    fi
    
    check_health
    if [ $? -ne 0 ]; then
        log_warning "健康检查失败，尝试重启服务..."
        ./scripts/restart.sh
        sleep 10
        check_health
        if [ $? -ne 0 ]; then
            log_error "服务重启后健康检查仍然失败"
            exit 1
        fi
    fi
    
    check_resources
    check_logs
    
    log_success "监控完成，服务运行正常"
}

# 使用说明
usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  status    显示服务状态"
    echo "  monitor   执行完整监控"
    echo "  health    仅检查健康状态"
    echo "  logs      查看应用日志"
    echo "  restart   重启服务"
    echo "  help      显示此帮助信息"
    echo ""
}

# 主函数
main() {
    case "${1:-monitor}" in
        "status")
            show_status
            ;;
        "monitor")
            monitor
            ;;
        "health")
            check_health
            ;;
        "logs")
            docker-compose logs -f
            ;;
        "restart")
            ./scripts/restart.sh
            ;;
        "help")
            usage
            ;;
        *)
            log_error "未知选项: $1"
            usage
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"