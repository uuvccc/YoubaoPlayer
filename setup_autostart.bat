@echo off
chcp 65001 >nul
title YoubaoPlayer 快速配置向导
cd /d "%~dp0"

echo ========================================
echo   YoubaoPlayer 快速配置向导
echo ========================================
echo.
echo 本向导将帮助你完成：
echo   1. 设置环境变量（VPS_IP, SSH_PASS）
echo   2. 配置开机自启动
echo   3. 生成媒体列表
echo.

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [-] 请以管理员身份运行此脚本
    echo     右键点击脚本 -> "以管理员身份运行"
    pause
    exit /b 1
)

echo ========================================
echo   步骤 1/3: 配置 VPS 连接信息
echo ========================================
echo.

set /p VPS_IP_INPUT="请输入 VPS IP 地址: "
if "%VPS_IP_INPUT%"=="" (
    echo [-] IP 地址不能为空
    pause
    exit /b 1
)

set /p SSH_PASS_INPUT="请输入 SSH 密码: "
if "%SSH_PASS_INPUT%"=="" (
    echo [-] 密码不能为空
    pause
    exit /b 1
)

set /p VPS_USER_INPUT="请输入 SSH 用户名 (默认 root): "
if "%VPS_USER_INPUT%"=="" set VPS_USER_INPUT=root

echo.
echo [*] 正在保存环境变量...

:: 使用 PowerShell 设置永久环境变量
powershell -Command "[Environment]::SetEnvironmentVariable('VPS_IP', '%VPS_IP_INPUT%', 'User')"
powershell -Command "[Environment]::SetEnvironmentVariable('SSH_PASS', '%SSH_PASS_INPUT%', 'User')"
powershell -Command "[Environment]::SetEnvironmentVariable('VPS_USER', '%VPS_USER_INPUT%', 'User')"

if %errorLevel% equ 0 (
    echo [+] 环境变量已保存
    echo     VPS_IP = %VPS_IP_INPUT%
    echo     VPS_USER = %VPS_USER_INPUT%
) else (
    echo [-] 环境变量设置失败
    pause
    exit /b 1
)

echo.
echo ========================================
echo   步骤 2/3: 生成媒体列表
echo ========================================
echo.

if exist "config.json" (
    echo [*] 检测到 config.json，开始生成媒体列表...
    python manifest_generator.py
    if errorlevel 1 (
        echo [-] 生成失败，请检查 config.json 中的 media_dir 配置
        echo     但仍可继续配置开机自启
    ) else (
        echo [+] 媒体列表生成成功
    )
) else (
    echo [*] 未找到 config.json，跳过媒体列表生成
    echo     你可以稍后手动运行: python manifest_generator.py
)

echo.
echo ========================================
echo   步骤 3/3: 配置开机自启动
echo ========================================
echo.

set /p AUTO_START="是否配置开机自启？(Y/N，默认 Y): "
if /i "%AUTO_START%"=="N" goto SKIP_AUTOSTART
if /i "%AUTO_START%"=="NO" goto SKIP_AUTOSTART

:: 创建后台启动脚本
set "SCRIPT_DIR=%~dp0"
set "STARTUP_SCRIPT=%SCRIPT_DIR%start_silent.bat"

echo [*] 创建后台启动脚本...

(
echo @echo off
echo chcp 65001 ^>nul
echo cd /d "%%SCRIPT_DIR%%"
echo.
echo :: 等待网络就绪
echo timeout /t 10 /nobreak ^>nul
echo.
echo :: 生成媒体列表（如果需要）
echo if not exist "manifest.json" ^(
echo     python manifest_generator.py
echo ^)
echo.
echo :: 启动守护进程（自动监控和重启服务）
echo start "" /MIN python daemon.py
echo.
echo exit
) > "%%STARTUP_SCRIPT%%"

echo [+] 启动脚本已创建

:: 添加到任务计划程序
echo [*] 配置开机自启动任务...
set "TASK_NAME=YoubaoPlayer"

:: 删除旧任务（如果存在）
schtasks /delete /tn "%TASK_NAME%" /f >nul 2>&1

:: 创建新任务 - 登录时启动，延迟30秒
schtasks /create /tn "%TASK_NAME%" ^
    /tr "\"%STARTUP_SCRIPT%\"" ^
    /sc onlogon ^
    /rl highest ^
    /ru "%USERNAME%" ^
    /delay 0000:30 ^
    /f

if %errorLevel% equ 0 (
    echo [+] 开机自启配置成功！
    echo     任务名称: %TASK_NAME%
    echo     启动延迟: 30秒
) else (
    echo [-] 开机自启配置失败
    pause
    exit /b 1
)

:SKIP_AUTOSTART
echo.
echo ========================================
echo   配置完成！
echo ========================================
echo.
echo 已完成的配置：
echo   [√] 环境变量已设置
echo   [√] 媒体列表已生成（如适用）
if /i not "%AUTO_START%"=="N" if /i not "%AUTO_START%"=="NO" (
    echo   [√] 开机自启已配置
) else (
    echo   [×] 开机自启未配置
)
echo.
echo 下一步操作：
echo   1. 重启电脑测试开机自启（如已配置）
echo   2. 或手动启动：双击 start.bat
echo   3. 查看服务状态：访问 http://127.0.0.1:8900/
echo.
echo 管理命令：
echo   - 取消自启: 运行 autostart_remove.bat
echo   - 重新配置: 再次运行本脚本
echo   - 查看任务: taskschd.msc
echo.
pause
