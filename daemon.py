# -*- coding: utf-8 -*-
"""
YoubaoPlayer 守护进程
监控 server.py 和 tunnel.py，异常时自动重启
"""
import subprocess
import time
import sys
import os
import signal

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
SERVER_SCRIPT = os.path.join(SCRIPT_DIR, "server.py")
TUNNEL_SCRIPT = os.path.join(SCRIPT_DIR, "tunnel.py")

# 检查环境变量
if not os.environ.get("VPS_IP"):
    print("[-] 错误: 未设置环境变量 VPS_IP")
    sys.exit(1)

if not os.environ.get("SSH_PASS"):
    print("[-] 错误: 未设置环境变量 SSH_PASS")
    sys.exit(1)

def log(msg):
    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {msg}", flush=True)

def start_process(script_path, name):
    """启动子进程"""
    try:
        proc = subprocess.Popen(
            [sys.executable, script_path],
            cwd=SCRIPT_DIR,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            encoding='utf-8',
            errors='ignore'
        )
        log(f"[+] {name} 已启动 (PID: {proc.pid})")
        return proc
    except Exception as e:
        log(f"[-] {name} 启动失败: {e}")
        return None

def monitor_process(proc, name, restart_delay=5):
    """监控进程，崩溃时自动重启"""
    while True:
        if proc is None or proc.poll() is not None:
            log(f"[-] {name} 已停止，{restart_delay}秒后重启...")
            time.sleep(restart_delay)
            proc = start_process(
                TUNNEL_SCRIPT if name == "SSH Tunnel" else SERVER_SCRIPT,
                name
            )
        time.sleep(2)

def main():
    log("=" * 50)
    log("YoubaoPlayer 守护进程启动")
    log("=" * 50)
    
    # 启动两个服务
    server_proc = start_process(SERVER_SCRIPT, "HTTP Server")
    time.sleep(2)  # 等待服务器启动
    
    tunnel_proc = start_process(TUNNEL_SCRIPT, "SSH Tunnel")
    
    if not server_proc or not tunnel_proc:
        log("[-] 服务启动失败，退出")
        sys.exit(1)
    
    log("[+] 所有服务已启动，开始监控...")
    log("[+] 按 Ctrl+C 停止所有服务")
    
    try:
        # 同时监控两个进程
        while True:
            # 检查 HTTP 服务器
            if server_proc.poll() is not None:
                log("[-] HTTP Server 异常退出，重启中...")
                server_proc = start_process(SERVER_SCRIPT, "HTTP Server")
            
            # 检查 SSH 隧道
            if tunnel_proc.poll() is not None:
                log("[-] SSH Tunnel 异常退出，重启中...")
                tunnel_proc = start_process(TUNNEL_SCRIPT, "SSH Tunnel")
            
            time.sleep(3)
    
    except KeyboardInterrupt:
        log("\n[*] 收到停止信号...")
        
        # 停止所有子进程
        for proc, name in [(server_proc, "HTTP Server"), (tunnel_proc, "SSH Tunnel")]:
            if proc and proc.poll() is None:
                log(f"[*] 正在停止 {name}...")
                try:
                    proc.terminate()
                    proc.wait(timeout=5)
                except:
                    proc.kill()
        
        log("[+] 所有服务已停止")

if __name__ == "__main__":
    main()
