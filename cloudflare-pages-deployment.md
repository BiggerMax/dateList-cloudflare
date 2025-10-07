# Cloudflare Pages 部署指南

## 项目概述

这是一个日历记事本应用，包含前端静态文件和后端API服务。为了充分利用Cloudflare的优势，我们采用前后端分离部署：

- **前端**：部署到 Cloudflare Pages（静态站点托管）
- **后端**：部署到支持Docker的平台（如Railway、Render等）

## 前端部署到 Cloudflare Pages

### 步骤1：准备静态文件

前端文件已准备就绪，包含：
- `index.html` - 主页面
- `style.css` - 样式文件
- `script.js` - 前端逻辑
- `_headers` - Cloudflare Pages配置

### 步骤2：在Cloudflare Pages中创建项目

1. 访问 [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. 选择你的账户
3. 点击 "Pages" → "Create a project"
4. 选择 "Connect to Git"
5. 连接到你的GitHub仓库：`https://github.com/BiggerMax/dateList-cloudflare.git`
6. 构建配置：
   - **Build command**: 无需构建（纯静态文件）
   - **Build output directory**: `./` （根目录）
   - **Root directory**: `./` （根目录）

### 步骤3：环境变量配置

在Cloudflare Pages项目设置中添加环境变量：
```
API_BASE_URL=https://your-backend-service.com
```

## 后端部署选项

由于后端需要数据持久化和服务器端逻辑，推荐以下平台：

### 选项1：Railway（推荐）

Railway提供了简单的一键Docker部署：

1. 访问 [Railway](https://railway.app/)
2. 连接GitHub仓库
3. Railway会自动检测Dockerfile并部署
4. 部署完成后获取服务URL

### 选项2：Render

1. 访问 [Render](https://render.com/)
2. 创建新的Web服务
3. 连接GitHub仓库
4. Render会自动检测Dockerfile

### 选项3：其他平台

- **Fly.io**：全球分布式部署
- **Heroku**：经典PaaS平台
- **DigitalOcean App Platform**：云原生平台

## 部署后配置

### 1. 更新前端API地址

部署后端后，更新Cloudflare Pages中的环境变量：
```
API_BASE_URL=https://your-deployed-backend-url
```

### 2. 修改前端代码（如果需要）

如果后端部署在不同域名，需要修改`script.js`中的API地址：

```javascript
// 当前配置
const API_BASE = '/api'; // 相对路径，由_headers代理

// 如果需要绝对URL
const API_BASE = 'https://your-backend-domain.com/api';
```

### 3. 测试部署

1. 访问前端Pages域名，确认页面正常加载
2. 测试记事本功能，确认API调用正常
3. 测试数据持久化功能

## 故障排除

### 前端无法访问API

1. 检查`_headers`文件配置是否正确
2. 确认后端服务正在运行
3. 检查浏览器开发者工具中的网络请求

### 数据无法保存

1. 确认后端服务可写数据目录权限
2. 检查后端日志中的错误信息
3. 确认防火墙设置允许HTTP请求

## 成本估算

- **Cloudflare Pages**：免费额度包含100万请求/月
- **Railway**：免费额度包含$5美元额度，足够小型应用使用
- **Render**：免费额度包含750小时/月

## 监控和维护

### 日志监控

- Cloudflare Pages：访问Cloudflare Dashboard查看访问日志
- 后端平台：使用各自平台的日志功能

### 性能监控

- 使用Cloudflare Analytics监控前端性能
- 在后端添加健康检查端点：`/health`

### 数据备份

- 后端平台通常提供自动备份
- 可以使用应用内的Excel导出功能手动备份

## 扩展建议

### 添加自定义域名

1. 在Cloudflare Dashboard中添加自定义域名
2. 配置CNAME记录指向Pages域名
3. 申请SSL证书

### CDN优化

Cloudflare Pages自动提供全球CDN加速，无需额外配置。

### 缓存策略

如需优化性能，可以在`_headers`中添加缓存配置：

```
/*
  Cache-Control: public, max-age=3600
```

这个部署方案充分利用了Cloudflare的全球网络优势，同时保持了应用的完整功能。