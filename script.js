class CalendarNotebook {
    constructor() {
        this.currentDate = new Date();
        this.currentMonth = this.currentDate.getMonth();
        this.currentYear = this.currentDate.getFullYear();
        this.selectedDate = null;
        this.notes = {}; // 初始化为空对象
        this.initialized = false;
    }
    
    async init() {
        if (this.initialized) return; // 防止重复初始化
        
        await this.loadNotes(); // 先加载数据
        this.renderCalendar();
        this.bindEvents();
        this.startDataSync();
        this.setupPageVisibilityListener();
        this.initialized = true;
    }
    
    bindEvents() {
        // 月份切换按钮
        document.getElementById('prevMonth').addEventListener('click', () => {
            this.previousMonth();
        });
        
        document.getElementById('nextMonth').addEventListener('click', () => {
            this.nextMonth();
        });
        
        // 弹窗事件
        const modal = document.getElementById('editModal');
        const closeBtn = document.querySelector('.close');
        const saveBtn = document.getElementById('saveBtn');
        const cancelBtn = document.getElementById('cancelBtn');
        
        closeBtn.addEventListener('click', () => {
            this.closeModal();
        });
        
        cancelBtn.addEventListener('click', () => {
            this.closeModal();
        });
        
        saveBtn.addEventListener('click', async () => {
            await this.saveNotes();
        });
        
        // 导入导出按钮事件
        document.getElementById('exportBtn').addEventListener('click', () => {
            this.exportToExcel();
        });
        
        document.getElementById('importBtn').addEventListener('click', () => {
            document.getElementById('fileInput').click();
        });
        
        document.getElementById('fileInput').addEventListener('change', async (e) => {
            await this.importFromExcel(e);
        });
        
        // 点击弹窗外部关闭
        window.addEventListener('click', (e) => {
            if (e.target === modal) {
                this.closeModal();
            }
        });
    }
    
    renderCalendar() {
        const monthNames = [
            '一月', '二月', '三月', '四月', '五月', '六月',
            '七月', '八月', '九月', '十月', '十一月', '十二月'
        ];
        
        document.getElementById('currentMonth').textContent = 
            `${this.currentYear}年 ${monthNames[this.currentMonth]}`;
        
        const firstDay = new Date(this.currentYear, this.currentMonth, 1);
        const lastDay = new Date(this.currentYear, this.currentMonth + 1, 0);
        const daysInMonth = lastDay.getDate();
        
        const calendarDays = document.getElementById('calendarDays');
        calendarDays.innerHTML = '';
        
        // 计算第一天是周几 (0=周日, 1=周一, ..., 6=周六)
        let firstDayOfWeek = firstDay.getDay();
        // 调整为周一为0，周五为4
        if (firstDayOfWeek === 0) firstDayOfWeek = 6; // 周日变为周六
        else firstDayOfWeek -= 1; // 其他日子减1
        
        // 添加空白格子
        for (let i = 0; i < firstDayOfWeek; i++) {
            const emptyDay = document.createElement('div');
            emptyDay.className = 'day other-month';
            calendarDays.appendChild(emptyDay);
        }
        
        // 添加当月日期
        for (let day = 1; day <= daysInMonth; day++) {
            const dayElement = document.createElement('div');
            dayElement.className = 'day';
            
            // 检查是否是今天
            const today = new Date();
            if (this.currentYear === today.getFullYear() && 
                this.currentMonth === today.getMonth() && 
                day === today.getDate()) {
                dayElement.classList.add('today');
            }
            
            // 检查是否是周末
            const dateObj = new Date(this.currentYear, this.currentMonth, day);
            const dayOfWeek = dateObj.getDay();
            if (dayOfWeek === 0 || dayOfWeek === 6) {
                dayElement.style.display = 'none'; // 隐藏周末
            }
            
            dayElement.innerHTML = `
                <div class="day-number">${day}</div>
                <div class="day-notes" id="notes-${this.currentYear}-${this.currentMonth}-${day}"></div>
            `;
            
            dayElement.addEventListener('click', () => {
                this.openModal(day);
            });
            
            calendarDays.appendChild(dayElement);
            
            // 加载该日期的备注
            this.loadDayNotes(day);
        }
    }
    
    loadDayNotes(day) {
        const dateKey = `${this.currentYear}-${this.currentMonth}-${day}`;
        const dayNotes = this.notes[dateKey] || [];
        const notesContainer = document.getElementById(`notes-${this.currentYear}-${this.currentMonth}-${day}`);
        
        if (notesContainer) {
            notesContainer.innerHTML = '';
            dayNotes.forEach(note => {
                const noteElement = document.createElement('div');
                noteElement.className = 'day-note';
                noteElement.textContent = note.text;
                noteElement.style.fontFamily = note.font;
                noteElement.style.fontSize = note.size;
                noteElement.style.color = note.color;
                notesContainer.appendChild(noteElement);
            });
        }
    }
    
    openModal(day) {
        this.selectedDate = day;
        const modal = document.getElementById('editModal');
        const modalDate = document.getElementById('modalDate');
        
        modalDate.textContent = `${this.currentYear}年${this.currentMonth + 1}月${day}日`;
        
        // 加载该日期的现有备注
        const dateKey = `${this.currentYear}-${this.currentMonth}-${day}`;
        const dayNotes = this.notes[dateKey] || [];
        
        const inputs = document.querySelectorAll('.note-input');
        const fontSelects = document.querySelectorAll('.font-select');
        const sizeSelects = document.querySelectorAll('.size-select');
        const colorSelects = document.querySelectorAll('.color-select');
        
        // 清空输入框
        inputs.forEach(input => input.value = '');
        
        // 填充现有备注
        dayNotes.forEach((note, index) => {
            if (index < inputs.length) {
                inputs[index].value = note.text;
                fontSelects[index].value = note.font;
                sizeSelects[index].value = note.size;
                colorSelects[index].value = note.color;
            }
        });
        
        modal.style.display = 'block';
    }
    
    closeModal() {
        const modal = document.getElementById('editModal');
        modal.style.display = 'none';
        this.selectedDate = null;
    }
    
    async saveNotes() {
        if (!this.selectedDate) return;
        
        const dateKey = `${this.currentYear}-${this.currentMonth}-${this.selectedDate}`;
        const inputs = document.querySelectorAll('.note-input');
        const fontSelects = document.querySelectorAll('.font-select');
        const sizeSelects = document.querySelectorAll('.size-select');
        const colorSelects = document.querySelectorAll('.color-select');
        
        const dayNotes = [];
        
        for (let i = 0; i < inputs.length; i++) {
            const text = inputs[i].value.trim();
            if (text) {
                dayNotes.push({
                    text: text,
                    font: fontSelects[i].value,
                    size: sizeSelects[i].value,
                    color: colorSelects[i].value
                });
            }
        }
        
        this.notes[dateKey] = dayNotes;
        await this.saveNotesToStorage();
        this.loadDayNotes(this.selectedDate);
        this.closeModal();
    }
    
    previousMonth() {
        this.currentMonth--;
        if (this.currentMonth < 0) {
            this.currentMonth = 11;
            this.currentYear--;
        }
        this.renderCalendar();
    }
    
    nextMonth() {
        this.currentMonth++;
        if (this.currentMonth > 11) {
            this.currentMonth = 0;
            this.currentYear++;
        }
        this.renderCalendar();
    }
    
    async loadNotes() {
        try {
            // 首先尝试从服务器加载数据
            const response = await fetch('/api/notes');
            const result = await response.json();
            
            if (result.success) {
                // 同步本地存储
                this.notes = result.data;
                localStorage.setItem('calendarNotes', JSON.stringify(result.data));
                console.log('数据已从服务器加载');
            } else {
                throw new Error(result.message);
            }
        } catch (error) {
            console.error('从服务器加载数据失败:', error);
            // 如果服务器加载失败，回退到本地存储
            const saved = localStorage.getItem('calendarNotes');
            const localData = saved ? JSON.parse(saved) : {};
            
            this.notes = localData;
            
            // 尝试同步本地数据到服务器
            this.syncLocalToServer(localData);
            
            console.log('数据已从本地存储加载');
        }
    }
    
    // 同步本地数据到服务器
    async syncLocalToServer(localData) {
        try {
            const response = await fetch('/api/notes', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ notes: localData })
            });
            
            const result = await response.json();
            
            if (result.success) {
                console.log('本地数据已同步到服务器');
            }
        } catch (error) {
            console.error('同步本地数据到服务器失败:', error);
        }
    }
    
    // 定期同步数据
    startDataSync() {
        // 立即执行一次同步
        this.syncData();
        
        // 每30秒同步一次数据
        setInterval(() => {
            this.syncData();
        }, 30000); // 30秒
    }
    
    // 同步数据方法
    async syncData() {
        try {
            const response = await fetch('/api/notes');
            const result = await response.json();
            
            if (result.success) {
                const serverData = result.data;
                const localData = JSON.parse(localStorage.getItem('calendarNotes') || '{}');
                
                // 检查是否有新数据
                if (JSON.stringify(serverData) !== JSON.stringify(this.notes)) {
                    this.notes = serverData;
                    localStorage.setItem('calendarNotes', JSON.stringify(serverData));
                    this.renderCalendar();
                    console.log('数据已从服务器同步');
                }
            }
        } catch (error) {
            console.error('数据同步失败:', error);
        }
    }
    
    // 设置页面可见性监听器
    setupPageVisibilityListener() {
        document.addEventListener('visibilitychange', () => {
            if (!document.hidden) {
                // 页面重新可见时立即同步数据
                console.log('页面重新可见，开始同步数据');
                this.syncData();
            }
        });
        
        // 监听窗口获得焦点事件
        window.addEventListener('focus', () => {
            console.log('窗口获得焦点，开始同步数据');
            this.syncData();
        });
    }
    
    async saveNotesToStorage() {
        try {
            // 保存到服务器
            const response = await fetch('/api/notes', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ notes: this.notes })
            });
            
            const result = await response.json();
            
            if (result.success) {
                // 服务器保存成功，同时保存到本地作为备份
                localStorage.setItem('calendarNotes', JSON.stringify(this.notes));
                this.showMessage('数据已保存到服务器');
            } else {
                throw new Error(result.message);
            }
        } catch (error) {
            console.error('保存到服务器失败:', error);
            // 如果服务器保存失败，只保存到本地
            localStorage.setItem('calendarNotes', JSON.stringify(this.notes));
            this.showMessage('服务器保存失败，已保存到本地', 'error');
        }
    }
    
    exportToExcel() {
        const wb = XLSX.utils.book_new();
        const wsData = [['日期', '行号', '文字内容', '字体', '字号', '颜色']];
        
        // 将所有备注数据转换为表格格式
        Object.keys(this.notes).forEach(dateKey => {
            const dayNotes = this.notes[dateKey];
            dayNotes.forEach((note, index) => {
                wsData.push([
                    dateKey,
                    index + 1,
                    note.text,
                    note.font,
                    note.size,
                    note.color
                ]);
            });
        });
        
        const ws = XLSX.utils.aoa_to_sheet(wsData);
        XLSX.utils.book_append_sheet(wb, ws, '日历备注');
        
        // 生成文件名
        const now = new Date();
        const fileName = `日历备注_${now.getFullYear()}${(now.getMonth() + 1).toString().padStart(2, '0')}${now.getDate().toString().padStart(2, '0')}.xlsx`;
        
        XLSX.writeFile(wb, fileName);
    }
    
    async importFromExcel(event) {
        const file = event.target.files[0];
        if (!file) return;
        
        const reader = new FileReader();
        reader.onload = async (e) => {
            try {
                const data = new Uint8Array(e.target.result);
                const workbook = XLSX.read(data, { type: 'array' });
                const firstSheet = workbook.Sheets[workbook.SheetNames[0]];
                const jsonData = XLSX.utils.sheet_to_json(firstSheet, { header: 1 });
                
                // 清空现有数据
                this.notes = {};
                
                // 解析Excel数据
                for (let i = 1; i < jsonData.length; i++) {
                    const row = jsonData[i];
                    if (row.length >= 6 && row[0]) {
                        const dateKey = row[0].toString();
                        const text = row[2] ? row[2].toString() : '';
                        const font = row[3] ? row[3].toString() : 'Arial';
                        const size = row[4] ? row[4].toString() : '12px';
                        const color = row[5] ? row[5].toString() : '#000000';
                        
                        if (text.trim()) {
                            if (!this.notes[dateKey]) {
                                this.notes[dateKey] = [];
                            }
                            this.notes[dateKey].push({
                                text: text.trim(),
                                font: font,
                                size: size,
                                color: color
                            });
                        }
                    }
                }
                
                // 保存到服务器和本地存储
                await this.saveNotesToStorage();
                
                // 重新渲染日历
                this.renderCalendar();
                
                // 显示成功消息
                this.showMessage('Excel数据导入成功！');
                
            } catch (error) {
                console.error('导入Excel失败:', error);
                this.showMessage('导入Excel失败，请检查文件格式！', 'error');
            }
        };
        
        reader.readAsArrayBuffer(file);
        
        // 清空文件输入
        event.target.value = '';
    }
    
    showMessage(message, type = 'success') {
        // 创建消息提示
        const messageDiv = document.createElement('div');
        messageDiv.style.cssText = `
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 15px 20px;
            border-radius: 5px;
            color: white;
            font-weight: bold;
            z-index: 10000;
            animation: slideIn 0.3s ease-out;
            background: ${type === 'success' ? '#28a745' : '#dc3545'};
        `;
        messageDiv.textContent = message;
        
        document.body.appendChild(messageDiv);
        
        // 3秒后自动移除
        setTimeout(() => {
            if (messageDiv.parentNode) {
                messageDiv.parentNode.removeChild(messageDiv);
            }
        }, 3000);
    }
}

// 初始化日历记事本
document.addEventListener('DOMContentLoaded', async () => {
    const app = new CalendarNotebook();
    await app.init(); // 等待异步初始化完成
});