const express = require('express');
const path = require('path');
const cors = require('cors');
const fs = require('fs');

const app = express();
const PORT = process.env.PORT || 3001;
const DATA_FILE = process.env.DATA_FILE || path.join(__dirname, 'data.json');

// 内存缓存，减少文件IO
let dataCache = null;
let cacheTimestamp = 0;
const CACHE_TTL = parseInt(process.env.CACHE_TTL) || 30000; // 30秒缓存

// 优化数据加载，使用缓存
function loadData() {
    const now = Date.now();
    if (dataCache && (now - cacheTimestamp) < CACHE_TTL) {
        return dataCache;
    }
    
    try {
        ensureDataFile();
        const data = fs.readFileSync(DATA_FILE, 'utf8');
        dataCache = JSON.parse(data);
        cacheTimestamp = now;
        return dataCache;
    } catch (error) {
        console.error('加载数据文件失败:', error);
        return {};
    }
}

// 保存数据并更新缓存
function saveData(data) {
    try {
        ensureDataFile();
        fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
        dataCache = data;
        cacheTimestamp = Date.now();
        return true;
    } catch (error) {
        console.error('保存数据文件失败:', error);
        return false;
    }
}

// 确保数据目录和文件存在
function ensureDataFile() {
    const dataDir = path.dirname(DATA_FILE);
    if (!fs.existsSync(dataDir)) {
        fs.mkdirSync(dataDir, { recursive: true });
    }
    if (!fs.existsSync(DATA_FILE)) {
        fs.writeFileSync(DATA_FILE, JSON.stringify({}));
    }
}

// 中间件配置 - 优化性能
app.use(cors());
app.use(express.json({ limit: '10mb' })); // 限制请求体大小
app.use(express.static(path.join(__dirname, '.'), {
    maxAge: 86400000 // 1天缓存静态文件
}));

// 路由配置
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// API路由 - 获取所有备注数据
app.get('/api/notes', (req, res) => {
    try {
        const data = loadData();
        res.json({
            success: true,
            message: '日历备注数据获取成功',
            data: data
        });
    } catch (error) {
        console.error('获取数据失败:', error);
        res.status(500).json({
            success: false,
            message: '获取数据失败'
        });
    }
});

// API路由 - 保存备注数据
app.post('/api/notes', (req, res) => {
    try {
        const { notes } = req.body;
        
        if (saveData(notes)) {
            res.json({
                success: true,
                message: '日历备注数据保存成功',
                data: notes
            });
        } else {
            res.status(500).json({
                success: false,
                message: '保存数据文件失败'
            });
        }
    } catch (error) {
        console.error('保存数据失败:', error);
        res.status(500).json({
            success: false,
            message: '保存数据失败'
        });
    }
});

// API路由 - 获取特定日期的备注
app.get('/api/notes/:dateKey', (req, res) => {
    try {
        const { dateKey } = req.params;
        const data = loadData();
        const dayNotes = data[dateKey] || [];
        
        res.json({
            success: true,
            message: '获取日期备注成功',
            data: dayNotes
        });
    } catch (error) {
        console.error('获取日期备注失败:', error);
        res.status(500).json({
            success: false,
            message: '获取日期备注失败'
        });
    }
});

// API路由 - 更新特定日期的备注
app.put('/api/notes/:dateKey', (req, res) => {
    try {
        const { dateKey } = req.params;
        const { notes } = req.body;
        
        const data = loadData();
        data[dateKey] = notes;
        
        if (saveData(data)) {
            res.json({
                success: true,
                message: '更新日期备注成功',
                data: notes
            });
        } else {
            res.status(500).json({
                success: false,
                message: '更新数据文件失败'
            });
        }
    } catch (error) {
        console.error('更新数据失败:', error);
        res.status(500).json({
            success: false,
            message: '更新数据失败'
        });
    }
});

// API路由 - 备份数据
app.post('/api/notes/backup', (req, res) => {
    try {
        const data = loadData();
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        const backupFile = path.join(__dirname, `backup_${timestamp}.json`);
        
        fs.writeFileSync(backupFile, JSON.stringify(data, null, 2));
        
        res.json({
            success: true,
            message: '数据备份成功',
            backupFile: backupFile
        });
    } catch (error) {
        console.error('备份数据失败:', error);
        res.status(500).json({
            success: false,
            message: '备份数据失败'
        });
    }
});

// API路由 - 恢复数据
app.post('/api/notes/restore', (req, res) => {
    try {
        const { backupFile } = req.body;
        
        if (!fs.existsSync(backupFile)) {
            return res.status(404).json({
                success: false,
                message: '备份文件不存在'
            });
        }
        
        const backupData = fs.readFileSync(backupFile, 'utf8');
        const data = JSON.parse(backupData);
        
        if (saveData(data)) {
            res.json({
                success: true,
                message: '数据恢复成功',
                data: data
            });
        } else {
            res.status(500).json({
                success: false,
                message: '恢复数据失败'
            });
        }
    } catch (error) {
        console.error('恢复数据失败:', error);
        res.status(500).json({
            success: false,
            message: '恢复数据失败'
        });
    }
});

// 健康检查端点
app.get('/health', (req, res) => {
    res.json({
        status: 'OK',
        timestamp: new Date().toISOString(),
        service: 'Calendar Notebook'
    });
});

// 错误处理中间件
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        success: false,
        message: '服务器内部错误'
    });
});

// 404处理
app.use((req, res) => {
    res.status(404).json({
        success: false,
        message: '请求的资源不存在'
    });
});

// 启动服务器
app.listen(PORT, () => {
    console.log(`🚀 日历记事本服务器已启动`);
    console.log(`📱 本地访问地址: http://localhost:${PORT}`);
    console.log(`🔍 健康检查: http://localhost:${PORT}/health`);
    console.log(`📝 API端点: http://localhost:${PORT}/api/notes`);
    console.log(`⚙️  服务器运行在端口 ${PORT}`);
    console.log(`🌐 按 Ctrl+C 停止服务器`);
});

// 优雅关闭处理
process.on('SIGINT', () => {
    console.log('\n🛑 正在关闭服务器...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\n🛑 正在关闭服务器...');
    process.exit(0);
});

module.exports = app;