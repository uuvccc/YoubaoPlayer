@echo off
chcp 65001 >nul
title YoubaoPlayer 一键启动
cd /d "%~dp0"

echo ========================================
echo   YoubaoPlayer 攸宝相册播放器
echo ========================================
echo.

:: 检查环境变量
if "%VPS_IP%"=="" (
    echo [-] 请设置环境变量 VPS_IP
    echo     set VPS_IP=your.vps.ip.address
    pause
    exit /b 1
)
if "%VPS_USER%"=="" set VPS_USER=root
if "%SSH_PASS%"=="" (
    echo [-] 请设置环境变量 SSH_PASS
    echo     set SSH_PASS=your_ssh_password
    pause
    exit /b 1
)

:: 检查 manifest.json
if not exist "manifest.json" (
    echo [*] 正在生成媒体列表...
    python manifest_generator.py
    if errorlevel 1 (
        echo [-] 生成失败，请检查 config.json 中的 media_dir 配置
        pause
        exit /b 1
    )
    echo [+] 媒体列表生成完成
    echo.
)

:: 启动 HTTP 服务器（后台）
echo [*] 启动 HTTP 服务器...
start "YoubaoPlayer Server" python server.py

timeout /t 2 /nobreak >nul

python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8900/', timeout=3)" 2>nul
if errorlevel 1 (
    echo [-] 服务器启动失败
    pause
    exit /b 1
)
echo [+] HTTP 服务器已启动: http://127.0.0.1:8900/
echo.

:: 启动 SSH 反向隧道（后台，支持自动重连）
echo [*] 启动 SSH 反向隧道...
start "SSH Tunnel" python tunnel.py

timeout /t 3 /nobreak >nul

echo [+] SSH 隧道已启动（支持自动重连）
echo [+] 外网访问: http://%VPS_IP%/youbaoplayer/
echo.
echo ========================================
echo   启动完成！
echo   本地: http://127.0.0.1:8900/
echo   外网: http://%VPS_IP%/youbaoplayer/
echo ========================================
echo.
echo 按任意键停止所有服务...
pause >nul

taskkill /FI "WINDOWTITLE eq YoubaoPlayer Server*" /F 2>nul
taskkill /FI "WINDOWTITLE eq SSH Tunnel*" /F 2>nul

echo.
echo [+] 服务已停止
