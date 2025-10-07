# 日历记事本 - 一键部署指南

## 快速开始

### 1. 一键部署
```bash
./setup.sh
```

### 2. 手动部署
```bash
# 创建必要目录
mkdir -p data backups logs

# 复制环境配置
cp .env.example .env

# 构建并启动
docker-compose up -d
```

## 管理脚本

### 服务管理
```bash
# 启动服务
./scripts/start.sh

# 停止服务
./scripts/stop.sh

# 重启服务
./scripts/restart.sh
```

### 数据管理
```bash
# 备份数据
./scripts/backup.sh

# 恢复数据
./scripts/restore.sh [备份文件名]

# 监控服务
./scripts/monitor.sh          # 完整监控
./scripts/monitor.sh status   # 显示状态
./scripts/monitor.sh health   # 健康检查
./scripts/monitor.sh logs     # 查看日志
```

### Docker命令
```bash
# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f

# 进入容器
docker-compose exec calendar-notebook sh

# 停止并删除容器
docker-compose down

# 重新构建
docker-compose build --no-cache
```

## 访问信息

- **应用地址**: http://localhost:3001
- **健康检查**: http://localhost:3001/health
- **API端点**: http://localhost:3001/api/notes

## 目录结构

```
dateList/
├── data/           # 数据文件目录
├── backups/        # 备份文件目录
├── logs/           # 日志文件目录
├── scripts/        # 管理脚本
│   ├── start.sh    # 启动脚本
│   ├── stop.sh     # 停止脚本
│   ├── restart.sh  # 重启脚本
│   ├── backup.sh   # 备份脚本
│   ├── restore.sh  # 恢复脚本
│   └── monitor.sh  # 监控脚本
├── Dockerfile      # Docker镜像配置
├── docker-compose.yml # Docker编排配置
├── .env.example    # 环境配置示例
└── setup.sh        # 一键部署脚本
```

## 系统要求

- Docker >= 19.03
- Docker Compose >= 1.29
- 内存 >= 256MB
- 磁盘空间 >= 500MB

## 故障排除

### 1. 服务无法启动
```bash
# 检查Docker服务
docker info

# 查看详细日志
docker-compose logs --tail=100

# 检查端口占用
netstat -tlnp | grep 3001
```

### 2. 数据丢失
```bash
# 检查数据文件
ls -la data/

# 恢复备份
./scripts/restore.sh
```

### 3. 性能问题
```bash
# 监控资源使用
./scripts/monitor.sh

# 检查容器资源
docker stats calendar-notebook
```

## 配置优化

### 环境变量配置
编辑 `.env` 文件调整以下参数：

```bash
# 服务端口
PORT=3001

# 数据文件路径
DATA_FILE=/app/data/data.json

# 缓存时间（毫秒）
CACHE_TTL=30000

# 内存限制
NODE_MAX_MEMORY=256MB
```

### Docker资源限制
编辑 `docker-compose.yml` 中的资源限制：

```yaml
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 256M
    reservations:
      cpus: '0.1'
      memory: 128M
```

## 自动化建议

### 1. 定时备份
添加到 crontab:
```bash
# 每天凌晨2点备份
0 2 * * * /path/to/dateList/scripts/backup.sh
```

### 2. 健康检查监控
```bash
# 每5分钟检查一次
*/5 * * * * /path/to/dateList/scripts/monitor.sh health
```

### 3. 日志轮转
配置 logrotate 或使用 Docker 日志驱动。

## 安全建议

1. 定期更新基础镜像
2. 使用非root用户运行容器
3. 限制容器资源使用
4. 定期备份数据
5. 监控服务健康状态