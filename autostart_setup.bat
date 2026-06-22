@echo off
chcp 65001 >nul
title YoubaoPlayer 开机自启配置
cd /d "%~dp0"

echo ========================================
echo   YoubaoPlayer 开机自启配置工具
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

:: 获取当前用户和脚本路径
set "SCRIPT_DIR=%~dp0"
set "STARTUP_SCRIPT=%SCRIPT_DIR%start_silent.bat"

echo [*] 创建后台启动脚本...

:: 创建静默启动脚本（不显示窗口）
(
echo @echo off
echo chcp 65001 ^>nul
echo cd /d "%SCRIPT_DIR%"
echo.
echo :: 检查环境变量是否已设置
echo if "%%VPS_IP%%"=="" ^(
echo     echo [错误] 请先设置环境变量 VPS_IP
echo     exit /b 1
echo ^)
echo if "%%SSH_PASS%%"=="" ^(
echo     echo [错误] 请先设置环境变量 SSH_PASS
echo     exit /b 1
echo ^)
echo.
echo :: 生成媒体列表（如果需要）
echo if not exist "manifest.json" ^(
echo     python manifest_generator.py
echo ^)
echo.
echo :: 启动 HTTP 服务器
echo start "" /MIN python server.py
echo timeout /t 2 /nobreak ^>nul
echo.
echo :: 启动 SSH 隧道
echo start "" /MIN python tunnel.py
echo.
echo exit
) > "%STARTUP_SCRIPT%"

echo [+] 启动脚本已创建: %STARTUP_SCRIPT%
echo.

:: 添加到任务计划程序
echo [*] 配置开机自启动...
set "TASK_NAME=YoubaoPlayer"

:: 删除旧任务（如果存在）
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

:: 创建新任务
schtasks /create /tn "%TASK_NAME%" ^
    /tr "\"%STARTUP_SCRIPT%\"" ^
    /sc onlogon ^
    /rl highest ^
    /ru "%USERNAME%" ^
    /delay 0000:30 ^
    /f

if %errorLevel% equ 0 (
    echo [+] 开机自启配置成功！
    echo [+] 任务名称: %TASK_NAME%
    echo [+] 将在登录后30秒自动启动
    echo.
    echo ========================================
    echo   配置完成！
    echo ========================================
    echo.
    echo 提示:
    echo   - 确保已设置环境变量 VPS_IP 和 SSH_PASS
    echo   - 查看任务: taskschd.msc
    echo   - 删除自启: schtasks /delete /tn "%TASK_NAME%" /f
    echo   - 手动启动: 双击 start.bat
) else (
    echo [-] 配置失败，请检查错误信息
)

echo.
pause
