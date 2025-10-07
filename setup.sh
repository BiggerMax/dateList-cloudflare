#!/bin/bash

# 日历记事本一键部署脚本
# 适用于低配置服务器

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."
    
    # 检查Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    # 检查Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    # 检查内存
    TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
    if [ "$TOTAL_MEM" -lt 256 ]; then
        log_warning "系统内存不足256MB，可能影响性能"
    fi
    
    log_success "系统要求检查通过"
}

# 创建必要的目录
create_directories() {
    log_info "创建必要的目录..."
    
    mkdir -p data
    mkdir -p backups
    mkdir -p logs
    
    log_success "目录创建完成"
}

# 配置环境变量
setup_environment() {
    log_info "配置环境变量..."
    
    if [ ! -f .env ]; then
        cp .env.example .env
        log_success "环境配置文件已创建: .env"
    else
        log_info "环境配置文件已存在: .env"
    fi
}

# 设置权限
setup_permissions() {
    log_info "设置文件权限..."
    
    chmod +x scripts/*.sh 2>/dev/null || true
    chmod 755 data backups logs 2>/dev/null || true
    
    log_success "权限设置完成"
}

# 构建Docker镜像
build_docker() {
    log_info "构建Docker镜像..."
    
    docker-compose build --no-cache
    
    if [ $? -eq 0 ]; then
        log_success "Docker镜像构建成功"
    else
        log_error "Docker镜像构建失败"
        exit 1
    fi
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    docker-compose up -d
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 10
    
    # 检查服务状态
    if docker-compose ps | grep -q "Up"; then
        log_success "服务启动成功"
    else
        log_error "服务启动失败"
        docker-compose logs
        exit 1
    fi
}

# 验证部署
verify_deployment() {
    log_info "验证部署..."
    
    # 检查健康状态
    if curl -f http://localhost:3001/health > /dev/null 2>&1; then
        log_success "健康检查通过"
    else
        log_warning "健康检查失败，但服务可能仍在启动中"
    fi
    
    # 显示访问信息
    log_success "部署完成！"
    echo ""
    echo "=============================================="
    echo "🚀 日历记事本已成功部署"
    echo "📱 访问地址: http://localhost:3001"
    echo "🔍 健康检查: http://localhost:3001/health"
    echo "📝 数据目录: $(pwd)/data"
    echo "💾 备份目录: $(pwd)/backups"
    echo "📋 日志目录: $(pwd)/logs"
    echo "=============================================="
    echo ""
    echo "常用命令:"
    echo "  查看状态: docker-compose ps"
    echo "  查看日志: docker-compose logs -f"
    echo "  停止服务: docker-compose down"
    echo "  重启服务: docker-compose restart"
    echo ""
}

# 主函数
main() {
    echo "=============================================="
    echo "🗓️  日历记事本一键部署脚本"
    echo "=============================================="
    echo ""
    
    check_requirements
    create_directories
    setup_environment
    setup_permissions
    build_docker
    start_services
    verify_deployment
}

# 运行主函数
main "$@"