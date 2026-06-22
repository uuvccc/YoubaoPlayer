@echo off
chcp 65001 >nul
title YoubaoPlayer 取消开机自启
cd /d "%~dp0"

echo ========================================
echo   YoubaoPlayer 取消开机自启
echo ========================================
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [-] 请以管理员身份运行此脚本
    echo     右键点击脚本 -> "以管理员身份运行"
    pause
    exit /b 1
)

set "TASK_NAME=YoubaoPlayer"

echo [*] 正在删除开机启动任务...

schtasks /delete /tn "%TASK_NAME%" /f

if %errorLevel% equ 0 (
    echo [+] 开机自启已取消！
    echo.
    
    :: 删除静默启动脚本
    if exist "start_silent.bat" (
        del "start_silent.bat"
        echo [+] 已删除启动脚本: start_silent.bat
    )
) else (
    echo [-] 删除失败，可能任务不存在
)

echo.
pause
