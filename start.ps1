# YoubaoPlayer 一键启动脚本
# 依赖:
#   1. Python (内置 HTTP 服务器)
#   2. 系统 ssh (Windows 自带)
#   3. SSH 密钥文件 (位于 ~/.ssh/id_tunnel)
#
# VPS 要求:
#   - YOUR_VPS_IP
#   - /etc/ssh/sshd_config 中 AllowTcpForwarding yes
#   - Nginx 配置 /youbaoplayer/ -> http://127.0.0.1:18080/

$ErrorActionPreference = "Continue"
$PROJECT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $PROJECT_DIR

$VPS = "YOUR_VPS_IP"
$VPS_USER = "root"
$KEY_PATH = "$env:USERPROFILE\.ssh\id_tunnel"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   YoubaoPlayer 攸宝相册播放器" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查密钥
if (-not (Test-Path $KEY_PATH)) {
    Write-Host "[-] SSH 密钥不存在: $KEY_PATH" -ForegroundColor Red
    Write-Host "    请先运行: ssh-keygen -t rsa -b 4096 -f `"$KEY_PATH`" -N '""'"
    Write-Host "    然后把公钥上传到 VPS: ${VPS_USER}@${VPS}:~/.ssh/authorized_keys"
    pause
    exit 1
}

# 检查本地服务器
Write-Host "[*] 检查本地服务器..."
try {
    $resp = Invoke-WebRequest -Uri "http://127.0.0.1:8900/" -TimeoutSec 3 -UseBasicParsing
    Write-Host "[+] 本地服务器已运行 (端口 8900)" -ForegroundColor Green
} catch {
    Write-Host "[*] 启动本地 HTTP 服务器..." -ForegroundColor Yellow
    $serverJob = Start-Job -ScriptBlock {
        Set-Location $using:PROJECT_DIR
        python server.py
    }
    Start-Sleep -Seconds 2
    try {
        $resp = Invoke-WebRequest -Uri "http://127.0.0.1:8900/" -TimeoutSec 3 -UseBasicParsing
        Write-Host "[+] 本地服务器已启动" -ForegroundColor Green
    } catch {
        Write-Host "[-] 本地服务器启动失败" -ForegroundColor Red
        pause
        exit 1
    }
}

Write-Host ""

# 检查 VPS 上 18080 端口是否被占用
Write-Host "[*] 检查 VPS 端口状态..."
$portStatus = ssh -i $KEY_PATH -o StrictHostKeyChecking=no -o BatchMode=yes ${VPS_USER}@${VPS} "ss -tlnp | grep :18080 | head -1" 2>$null
if ($portStatus -match '18080') {
    Write-Host "[!] VPS 端口 18080 被占用，正在清理..." -ForegroundColor Yellow
    ssh -i $KEY_PATH -o StrictHostKeyChecking=no -o BatchMode=yes ${VPS_USER}@${VPS} 'fuser -k 18080/tcp 2>/dev/null; sleep 1' 2>$null
} else {
    Write-Host "[+] VPS 端口 18080 可用" -ForegroundColor Green
}

Write-Host ""

# 启动 SSH 反向隧道
Write-Host "[*] 启动 SSH 反向隧道..."
$sshProc = Start-Process -FilePath "ssh" -ArgumentList @(
    "-i", "`"$KEY_PATH`"",
    "-o", "StrictHostKeyChecking=no",
    "-o", "ExitOnForwardFailure=yes",
    "-o", "ServerAliveInterval=30",
    "-o", "ServerAliveCountMax=3",
    "-R", "18080:127.0.0.1:8900",
    "-N", "${VPS_USER}@${VPS}"
) -PassThru -NoNewWindow

Start-Sleep -Seconds 3

# 测试外网访问
Write-Host "[*] 测试外网访问..."
try {
    $resp = Invoke-WebRequest -Uri "http://$VPS/youbaoplayer/" -TimeoutSec 10 -UseBasicParsing
    Write-Host "[+] 外网访问正常！" -ForegroundColor Green
} catch {
    Write-Host "[-] 外网访问失败: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Red
    Write-Host "    错误信息: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "   启动完成！" -ForegroundColor Green
Write-Host "   本地: http://127.0.0.1:8900/" -ForegroundColor Green
Write-Host "   外网: http://$VPS/youbaoplayer/" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "按任意键停止所有服务..." -ForegroundColor Yellow
[void][System.Console]::ReadKey()

Write-Host ""
Write-Host "[*] 正在停止服务..."

# 停止 SSH 隧道
try {
    Get-Process ssh -ErrorAction SilentlyContinue | Stop-Process -Force
} catch {}

# 停止本地服务器
try {
    Get-Process python -ErrorAction SilentlyContinue | Where-Object { $_.StartTime -gt (Get-Date).AddMinutes(-5) } | Stop-Process -Force
} catch {}

# 在 VPS 上清理端口
ssh -i $KEY_PATH -o StrictHostKeyChecking=no -o BatchMode=yes ${VPS_USER}@${VPS} 'fuser -k 18080/tcp 2>/dev/null; echo done' 2>$null | Out-Null

Write-Host "[+] 服务已停止" -ForegroundColor Green
