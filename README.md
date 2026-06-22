# YoubaoPlayer 攸宝相册播放器

一个轻量级的本地相册/视频播放器，支持随机播放、手机触摸操作，可通过内网穿透在外网访问。

## 功能特性

- **部分加载** — 从大量媒体文件中随机抽取50张，避免一次性加载过多导致卡顿
- **随机播放** — 支持随机顺序播放，每次“换一批”重新随机抽取
- **模式切换** — 全部 / 照片 / 视频 三种播放模式
- **手机适配** — 触摸滑动切换、双击暂停、按钮放大适配手指点击
- **视频片段** — 长视频自动随机截取30秒片段播放
- **键盘控制** — 支持方向键、空格、P、H、R等快捷键
- **内网穿透** — 可通过SSH反向隧道或frp实现外网访问
- **守护进程** — 服务异常时自动重启，保证7x24小时稳定运行

## 快速开始

### 1. 准备媒体文件

将照片和视频放入 `media` 目录（支持子目录）：

```
YoubaoPlayer/
├── media/
│   ├── photo1.jpg
│   ├── photo2.jpg
│   ├── 精选/
│   │   └── photo3.jpg
│   └── video1.mp4
```

### 2. 配置媒体目录

编辑 `config.json`：

```json
{
  "media_dir": "D:\\攸宝"
}
```

或直接将照片/视频放入项目目录的 `media/` 文件夹。

### 3. 快速配置（推荐）

**一键完成所有设置：**

1. 右键点击 `setup_autostart.bat`
2. 选择“**以管理员身份运行**”
3. 按提示输入 VPS 信息
4. 自动完成环境变量、媒体列表、开机自启配置

---

### 4. 手动启动（可选）

**Windows (PowerShell):****

```powershell
# 设置环境变量（首次使用）
$env:VPS_IP = "your.vps.ip.address"
$env:VPS_USER = "root"  # 可选，默认为 root

# 启动
.\start.ps1
```

**Windows (批处理):**

```batch
:: 设置环境变量（首次使用）
set VPS_IP=your.vps.ip.address
set VPS_USER=root
set SSH_PASS=your_ssh_password

:: 启动
start.bat
```

---

### 5. 管理开机自启

**取消自启：**
- 右键点击 `autostart_remove.bat`
- 选择“以管理员身份运行”

**查看任务：**
- 运行 `taskschd.msc` 打开任务计划程序
- 查找 "YoubaoPlayer" 任务

**重新配置：**
- 再次运行 `setup_autostart.bat` 即可

**手动配置：**

```bash
# 生成媒体列表（首次或新增文件后）
python manifest_generator.py

# 启动本地服务器
python server.py

# 启动 SSH 反向隧道（外网访问）
ssh -R 127.0.0.1:18080:127.0.0.1:8900 -N root@your-vps-ip
```

打开浏览器访问 `http://127.0.0.1:8900/`

## 操作方式

| 操作 | 说明 |
|------|------|
| 左右滑动 | 切换上一张/下一张 |
| 上下滑动 | 显示/隐藏控制栏 |
| 双击屏幕 | 暂停/继续 |
| ⏮/⏭ | 上一张/下一张 |
| ⏸ | 暂停/继续 |
| 🎬 | 切换全部/照片/视频模式 |
| 5秒 | 切换停留时间（3/5/8/12秒）|
| 🔀 | 切换随机/顺序播放 |
| 🔄 | 换一批（重新随机抽取50张）|
| 👁 | 隐藏/显示控制栏 |

## 键盘快捷键

| 按键 | 功能 |
|------|------|
| ←/→ | 切换图片 |
| 空格 | 下一张 |
| P | 暂停/继续 |
| H | 隐藏/显示控制栏 |
| R | 换一批 |

## 内网穿透（外网访问）

### 方式一：SSH反向隧道

在本地运行：

```bash
ssh -R 127.0.0.1:18080:127.0.0.1:8900 -N root@your-vps-ip
```

VPS上配置Nginx：

```nginx
location ^~ /youbaoplayer/ {
    proxy_pass http://127.0.0.1:18080/;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_read_timeout 86400;
}
```

### 方式二：frp

配置 `frpc.ini`：

```ini
[common]
server_addr = your-vps-ip
server_port = 7000

[youbao]
type = tcp
local_ip = 127.0.0.1
local_port = 8900
remote_port = 18080
```

## 项目结构

```
YoubaoPlayer/
├── index.html           # 播放器页面
├── server.py            # HTTP服务器
├── manifest_generator.py # 媒体列表生成器
├── manifest.json        # 媒体列表（自动生成）
├── media/               # 媒体文件目录
└── README.md
```

## 技术栈

- 前端：原生 HTML5 + CSS3 + JavaScript
- 后端：Python 3 + http.server
- 传输：SSH反向隧道 / frp

## 许可证

MIT License
