# 使用轻量级Node.js镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 创建app用户用于安全运行
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nextjs -u 1001

# 复制package.json和package-lock.json
COPY package*.json ./

# 安装依赖，使用--production只安装生产依赖
RUN npm ci --only=production && \
    npm cache clean --force

# 复制应用代码
COPY . .

# 创建数据目录并设置权限
RUN mkdir -p /app/data && \
    chown -R nextjs:nodejs /app

# 切换到非root用户
USER nextjs

# 暴露端口
EXPOSE 3001

# 设置环境变量
ENV NODE_ENV=production
ENV PORT=3001
ENV DATA_FILE=/app/data/data.json

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

# 启动应用
CMD ["node", "server.js"]