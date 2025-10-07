#!/bin/bash

# 日历记事本服务器启动脚本

echo "🚀 正在启动日历记事本服务器..."

# 检查Node.js是否安装
if ! command -v node &> /dev/null; then
    echo "❌ 错误: 未找到Node.js，请先安装Node.js"
    echo "下载地址: https://nodejs.org/"
    exit 1
fi

# 检查npm是否安装
if ! command -v npm &> /dev/null; then
    echo "❌ 错误: 未找到npm，请检查Node.js安装"
    exit 1
fi

# 检查是否已安装依赖
if [ ! -d "node_modules" ]; then
    echo "📦 正在安装依赖..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ 依赖安装失败"
        exit 1
    fi
fi

# 检查端口是否被占用
if lsof -Pi :3001 -sTCP:LISTEN -t >/dev/null ; then
    echo "⚠️  端口3001已被占用，正在尝试停止占用进程..."
    # 杀死占用端口的进程
    lsof -ti:3001 | xargs kill -9
    sleep 2
fi

echo "🔧 启动服务器..."
echo "📍 访问地址: http://localhost:3001"
echo "⏹️  按 Ctrl+C 停止服务器"
echo ""

# 启动服务器
npm start