#!/bin/bash

# 性能测试脚本

set -e

# 配置
SERVICE_URL="http://localhost:3001"
HEALTH_URL="$SERVICE_URL/health"
API_URL="$SERVICE_URL/api/notes"
TEST_DURATION=30  # 测试持续时间（秒）
CONCURRENT_USERS=10  # 并发用户数
RESULTS_DIR="./performance_results"

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 创建结果目录
mkdir -p "$RESULTS_DIR"

# 检查依赖
check_dependencies() {
    log_info "检查测试依赖..."
    
    # 检查curl
    if ! command -v curl &> /dev/null; then
        log_error "curl未安装"
        exit 1
    fi
    
    # 检查ab (Apache Benchmark)
    if ! command -v ab &> /dev/null; then
        log_warning "Apache Benchmark (ab)未安装，将使用简化测试"
        USE_AB=false
    else
        USE_AB=true
    fi
    
    # 检查jq (JSON处理器)
    if ! command -v jq &> /dev/null; then
        log_warning "jq未安装，将跳过JSON解析"
        USE_JQ=false
    else
        USE_JQ=true
    fi
    
    log_success "依赖检查完成"
}

# 检查服务状态
check_service() {
    log_info "检查服务状态..."
    
    if ! curl -f "$HEALTH_URL" > /dev/null 2>&1; then
        log_error "服务未运行或健康检查失败"
        exit 1
    fi
    
    log_success "服务运行正常"
}

# 测试响应时间
test_response_time() {
    log_info "测试响应时间..."
    
    local total_time=0
    local requests=0
    local max_time=0
    local min_time=999999
    
    for i in {1..50}; do
        local start_time=$(date +%s%N)
        local response=$(curl -s -w "%{http_code}" "$API_URL" -o /dev/null)
        local end_time=$(date +%s%N)
        
        if [ "$response" -eq 200 ]; then
            local elapsed=$((($end_time - $start_time) / 1000000))
            total_time=$(($total_time + $elapsed))
            requests=$(($requests + 1))
            
            if [ $elapsed -gt $max_time ]; then
                max_time=$elapsed
            fi
            
            if [ $elapsed -lt $min_time ]; then
                min_time=$elapsed
            fi
        fi
    done
    
    if [ $requests -gt 0 ]; then
        local avg_time=$(($total_time / $requests))
        echo "平均响应时间: ${avg_time}ms"
        echo "最小响应时间: ${min_time}ms"
        echo "最大响应时间: ${max_time}ms"
        echo "成功请求数: $requests"
        
        # 记录结果
        echo "$avg_time,$min_time,$max_time,$requests" >> "$RESULTS_DIR/response_time.csv"
    else
        log_error "所有请求都失败了"
    fi
}

# 测试并发性能
test_concurrent() {
    log_info "测试并发性能..."
    
    if [ "$USE_AB" = true ]; then
        log_info "使用Apache Benchmark进行并发测试..."
        
        # 生成测试数据
        local test_data='{"notes":{"2024-01-01":[{"id":"test","content":"测试数据","timestamp":"'$(date -Iseconds)'"}]}}'
        
        # 运行ab测试
        ab -n 1000 -c $CONCURRENT_USERS -T "application/json" -p /dev/null "$API_URL" > "$RESULTS_DIR/ab_results.txt" 2>&1
        
        if [ $? -eq 0 ]; then
            log_success "并发测试完成"
            echo "详细结果: $RESULTS_DIR/ab_results.txt"
        else
            log_error "并发测试失败"
        fi
    else
        log_info "使用简化并发测试..."
        
        # 简化的并发测试
        local success_count=0
        local fail_count=0
        local start_time=$(date +%s)
        
        # 启动并发请求
        for i in $(seq 1 $CONCURRENT_USERS); do
            {
                for j in {1..20}; do
                    if curl -s "$API_URL" > /dev/null; then
                        echo "success" >> "$RESULTS_DIR/concurrent_$i.log"
                    else
                        echo "fail" >> "$RESULTS_DIR/concurrent_$i.log"
                    fi
                done
            } &
        done
        
        # 等待所有请求完成
        wait
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        # 统计结果
        success_count=$(find "$RESULTS_DIR" -name "concurrent_*.log" -exec grep -c "success" {} \; | awk '{sum+=$1} END {print sum}')
        fail_count=$(find "$RESULTS_DIR" -name "concurrent_*.log" -exec grep -c "fail" {} \; | awk '{sum+=$1} END {print sum}')
        
        echo "并发测试结果:"
        echo "  成功请求: $success_count"
        echo "  失败请求: $fail_count"
        echo "  测试时长: ${duration}s"
        echo "  QPS: $((success_count / duration))"
        
        echo "$success_count,$fail_count,$duration,$((success_count / duration))" >> "$RESULTS_DIR/concurrent.csv"
        
        # 清理临时文件
        rm -f "$RESULTS_DIR"/concurrent_*.log
    fi
}

# 测试内存使用
test_memory() {
    log_info "测试内存使用..."
    
    if docker ps | grep -q "calendar-notebook"; then
        # 获取容器内存使用
        local memory_usage=$(docker stats calendar-notebook --no-stream --format "{{.MemUsage}}" | awk '{print $1}')
        local memory_percent=$(docker stats calendar-notebook --no-stream --format "{{.MemPerc}}" | sed 's/%//')
        
        echo "内存使用: $memory_usage"
        echo "内存百分比: $memory_percent%"
        
        echo "$memory_usage,$memory_percent" >> "$RESULTS_DIR/memory.csv"
    else
        log_warning "容器未运行，跳过内存测试"
    fi
}

# 测试CPU使用
test_cpu() {
    log_info "测试CPU使用..."
    
    if docker ps | grep -q "calendar-notebook"; then
        # 获取容器CPU使用
        local cpu_usage=$(docker stats calendar-notebook --no-stream --format "{{.CPUPerc}}" | sed 's/%//')
        
        echo "CPU使用: $cpu_usage%"
        
        echo "$cpu_usage" >> "$RESULTS_DIR/cpu.csv"
    else
        log_warning "容器未运行，跳过CPU测试"
    fi
}

# 测试磁盘IO
test_disk_io() {
    log_info "测试磁盘IO..."
    
    if [ -f "data/data.json" ]; then
        local file_size=$(du -b data/data.json | cut -f1)
        local read_time=$(dd if=data/data.json of=/dev/null bs=4k 2>&1 | grep -o '[0-9.]* [GMK]*B/s' | tail -1)
        
        echo "数据文件大小: $file_size bytes"
        echo "读取速度: $read_time"
        
        echo "$file_size,$read_time" >> "$RESULTS_DIR/disk_io.csv"
    else
        log_warning "数据文件不存在，跳过磁盘IO测试"
    fi
}

# 生成报告
generate_report() {
    log_info "生成性能报告..."
    
    local report_file="$RESULTS_DIR/performance_report_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 性能测试报告

测试时间: $(date)
测试环境: $(uname -a)

## 测试结果

### 响应时间测试
EOF
    
    if [ -f "$RESULTS_DIR/response_time.csv" ]; then
        echo "#### 响应时间数据" >> "$report_file"
        echo "| 平均响应时间 | 最小响应时间 | 最大响应时间 | 成功请求数 |" >> "$report_file"
        echo "|-------------|-------------|-------------|-----------|" >> "$report_file"
        tail -1 "$RESULTS_DIR/response_time.csv" | awk -F',' '{printf "| %sms | %sms | %sms | %d |\n", $1, $2, $3, $4}' >> "$report_file"
    fi
    
    if [ -f "$RESULTS_DIR/concurrent.csv" ]; then
        echo "" >> "$report_file"
        echo "#### 并发测试数据" >> "$report_file"
        echo "| 成功请求 | 失败请求 | 测试时长 | QPS |" >> "$report_file"
        echo "|---------|---------|---------|-----|" >> "$report_file"
        tail -1 "$RESULTS_DIR/concurrent.csv" | awk -F',' '{printf "| %d | %d | %ds | %d |\n", $1, $2, $3, $4}' >> "$report_file"
    fi
    
    if [ -f "$RESULTS_DIR/memory.csv" ]; then
        echo "" >> "$report_file"
        echo "#### 内存使用数据" >> "$report_file"
        echo "| 内存使用 | 内存百分比 |" >> "$report_file"
        echo "|---------|-----------|" >> "$report_file"
        tail -1 "$RESULTS_DIR/memory.csv" | awk -F',' '{printf "| %s | %s%% |\n", $1, $2}' >> "$report_file"
    fi
    
    if [ -f "$RESULTS_DIR/cpu.csv" ]; then
        echo "" >> "$report_file"
        echo "#### CPU使用数据" >> "$report_file"
        echo "| CPU使用率 |" >> "$report_file"
        echo "|-----------|" >> "$report_file"
        tail -1 "$RESULTS_DIR/cpu.csv" | awk '{printf "| %s%% |\n", $1}' >> "$report_file"
    fi
    
    if [ -f "$RESULTS_DIR/disk_io.csv" ]; then
        echo "" >> "$report_file"
        echo "#### 磁盘IO数据" >> "$report_file"
        echo "| 文件大小 | 读取速度 |" >> "$report_file"
        echo "|---------|---------|" >> "$report_file"
        tail -1 "$RESULTS_DIR/disk_io.csv" | awk -F',' '{printf "| %s bytes | %s |\n", $1, $2}' >> "$report_file"
    fi
    
    log_success "性能报告已生成: $report_file"
}

# 主函数
main() {
    echo "=============================================="
    echo "🚀 日历记事本性能测试"
    echo "=============================================="
    echo ""
    
    check_dependencies
    check_service
    
    echo ""
    echo "开始性能测试..."
    echo ""
    
    test_response_time
    echo ""
    
    test_concurrent
    echo ""
    
    test_memory
    echo ""
    
    test_cpu
    echo ""
    
    test_disk_io
    echo ""
    
    generate_report
    
    log_success "性能测试完成！"
    echo "结果目录: $RESULTS_DIR"
}

# 运行主函数
main "$@"