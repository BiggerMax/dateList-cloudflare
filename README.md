# 日历记事本 (Calendar Notebook)

一个基于Web的日历记事本应用，支持备注、字体样式设置、Excel导入导出和服务器端数据存储功能。

## 功能特点

- 📅 只显示工作日（周一到周五）的日历界面
- 📝 每个日期支持6行备注，每行最多20个字符
- 🎨 支持自定义字体、字号（12px-20px）和颜色（黑、红、绿）
- 📊 支持Excel数据导入导出
- ☁️ 服务器端数据存储，支持多设备同步
- 🔄 自动数据同步和备份功能
- 💾 双重数据存储（服务器+本地）
- 📱 响应式设计，支持移动设备

## 技术栈

- **前端**: HTML5, CSS3, JavaScript (ES6+)
- **后端**: Node.js, Express
- **库**: SheetJS (Excel处理), Express, CORS
- **部署**: 支持任意Node.js环境

## 快速开始

### 环境要求

- Node.js >= 14.0.0
- npm 或 yarn

### 安装步骤

1. **克隆或下载项目文件**
   ```bash
   # 如果是git仓库
   git clone <repository-url>
   cd dateList
   ```

2. **安装依赖**
   ```bash
   npm install
   ```

3. **启动服务器**
   ```bash
   npm start
   ```

4. **访问应用**
   打开浏览器访问: http://localhost:3001

### 开发模式

```bash
npm run dev
```

开发模式会使用nodemon自动重启服务器。

## 项目结构

```
dateList/
├── index.html          # 主页面
├── style.css           # 样式文件
├── script.js           # 前端JavaScript
├── server.js           # Node.js服务器
├── data.json           # 数据存储文件（自动创建）
├── backup_*.json       # 数据备份文件（自动创建）
├── package.json        # 项目配置
├── README.md          # 说明文档
└── node_modules/      # 依赖包
```

## API端点

- `GET /` - 主页面
- `GET /health` - 健康检查
- `GET /api/notes` - 获取所有备注数据
- `POST /api/notes` - 保存所有备注数据
- `GET /api/notes/:dateKey` - 获取特定日期的备注
- `PUT /api/notes/:dateKey` - 更新特定日期的备注
- `POST /api/notes/backup` - 创建数据备份
- `POST /api/notes/restore` - 从备份恢复数据

## 使用说明

### 基本操作

1. **查看日历**: 应用启动后显示当前月份的日历
2. **切换月份**: 使用左右箭头按钮切换月份
3. **添加备注**: 点击任意日期打开编辑弹窗
4. **编辑备注**: 在弹窗中输入文字并设置样式
5. **保存备注**: 点击保存按钮完成编辑

### 数据同步和存储

- **自动同步**: 应用每30秒自动检查服务器数据更新
- **双重存储**: 数据同时保存在服务器和本地浏览器
- **错误恢复**: 服务器连接失败时自动使用本地数据
- **数据备份**: 支持手动创建数据备份文件

### 样式设置

- **字体**: 支持8种字体选择
- **字号**: 12px、14px、16px、18px、20px
- **颜色**: 黑色、红色、绿色

### 数据导入导出

#### 导出Excel
1. 点击右上角"导出Excel"按钮
2. 自动下载包含所有备注的Excel文件
3. 文件名格式: `日历备注_YYYYMMDD.xlsx`

#### 导入Excel
1. 点击右上角"导入Excel"按钮
2. 选择Excel文件（.xlsx或.xls格式）
3. 系统自动解析并导入数据
4. 导入成功后显示提示消息

**Excel格式要求:**
- 第一行: 日期、行号、文字内容、字体、字号、颜色
- 数据行: 对应各字段的具体值

## 部署到服务器

### 生产环境部署

1. **上传文件到服务器**
   ```bash
   # 使用scp上传
   scp -r dateList/ user@server:/path/to/directory/
   ```

2. **登录服务器并安装依赖**
   ```bash
   cd /path/to/directory/dateList
   npm install --production
   ```

3. **启动服务**
   ```bash
   npm start
   ```

### 使用PM2管理进程（推荐）

1. **安装PM2**
   ```bash
   npm install -g pm2
   ```

2. **启动应用**
   ```bash
   pm2 start server.js --name calendar-notebook
   ```

3. **设置开机自启**
   ```bash
   pm2 startup
   pm2 save
   ```

4. **常用PM2命令**
   ```bash
   pm2 list           # 查看所有进程
   pm2 logs           # 查看日志
   pm2 restart calendar-notebook  # 重启应用
   pm2 stop calendar-notebook     # 停止应用
   ```

### 使用Nginx反向代理

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 查看端口占用
   lsof -i :3001
   # 修改端口
   # 编辑server.js中的PORT变量
   ```

2. **依赖安装失败**
   ```bash
   # 清除缓存重新安装
   npm cache clean --force
   rm -rf node_modules package-lock.json
   npm install
   ```

3. **Excel导入失败**
   - 确保文件格式正确（.xlsx或.xls）
   - 检查Excel文件是否包含必需的列
   - 确保日期格式为YYYY-M-D格式

## 开发说明

### 添加新功能

1. 前端功能修改 `script.js`
2. 样式修改 `style.css`
3. 后端API修改 `server.js`
4. 依赖管理修改 `package.json`

### 数据结构

### 备注数据结构

```javascript
// 备注数据结构
{
  "2024-1-15": [
    {
      text: "会议记录",
      font: "Arial",
      size: "14px",
      color: "#000000"
    }
  ]
}
```

### 数据存储说明

- **主数据文件**: `data.json` - 存储所有备注数据
- **备份文件**: `backup_YYYY-MM-DDTHH-MM-SSZ.json` - 数据备份文件
- **数据同步**: 前端自动与服务器同步数据
- **数据格式**: JSON格式，支持跨平台使用

### 数据安全特性

- **文件持久化**: 数据保存在服务器文件系统中
- **自动备份**: 支持手动创建数据备份
- **错误恢复**: 服务器故障时自动回退到本地存储
- **数据同步**: 多设备间数据自动同步

## 许可证

MIT License

## 联系方式

如有问题或建议，请通过以下方式联系：

- 邮箱: [your-email@example.com]
- GitHub Issues: [repository/issues]

---

**注意**: 
1. 首次运行时请确保所有依赖已正确安装，并且3001端口未被占用
2. 数据会自动保存在 `data.json` 文件中，服务器重启后数据不会丢失
3. 建议定期使用备份功能保护重要数据
4. 多设备使用时确保所有设备访问同一个服务器地址