@echo off
chcp 65001 >nul
title YoubaoPlayer 重启服务
cd /d "%~dp0"

echo ========================================
echo   YoubaoPlayer 重启服务
echo ========================================
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [-] 请以管理员身份运行此脚本
    pause
    exit /b 1
)

echo [*] 正在停止现有服务...

:: 停止所有 Python 进程（YoubaoPlayer 相关）
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *YoubaoPlayer*" 2>nul
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *SSH Tunnel*" 2>nul
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *daemon*" 2>nul

:: 等待进程完全停止
timeout /t 2 /nobreak >nul

:: 也停止可能残留的进程
for /f "tokens=2" %%i in ('tasklist ^| findstr /i "python"') do (
    taskkill /F /PID %%i 2>nul
)

timeout /t 1 /nobreak >nul
echo [+] 旧服务已停止
echo.

echo [*] 重新启动服务...

:: 生成媒体列表（如果需要）
if not exist "manifest.json" (
    echo [*] 生成媒体列表...
    python manifest_generator.py
)

:: 启动守护进程
start "" /MIN python daemon.py

timeout /t 3 /nobreak >nul

:: 验证服务是否启动成功
python -c "import urllib.request; r = urllib.request.urlopen('http://127.0.0.1:8900/', timeout=5); print('[+] HTTP服务器已启动:', r.status)" 2>nul

if errorlevel 1 (
    echo [-] 服务启动失败，请检查日志
    pause
    exit /b 1
)

echo [+] SSH隧道已启动
echo.
echo ========================================
echo   重启完成！
echo ========================================
echo.
echo 服务状态：
echo   本地访问: http://127.0.0.1:8900/
if defined VPS_IP (
    echo   外网访问: http://%VPS_IP%/youbaoplayer/
)
echo.
echo 提示：
echo   - 服务由守护进程自动监控
echo   - 如需停止服务，请运行 autostart_remove.bat
echo   - 或手动结束 python 进程
echo.
pause
