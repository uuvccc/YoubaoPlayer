import os
import sys
import time
import threading
import select
import socket
import paramiko

VPS_IP = os.environ.get("VPS_IP", "")
VPS_USER = os.environ.get("VPS_USER", "root")
SSH_PASS = os.environ.get("SSH_PASS", "")
LOCAL_PORT = int(os.environ.get("LOCAL_PORT", "8900"))
REMOTE_PORT = int(os.environ.get("REMOTE_PORT", "18080"))

if not VPS_IP or not SSH_PASS:
    print("[-] 请设置环境变量: VPS_IP 和 SSH_PASS")
    sys.exit(1)


def tunnel_server(transport, remote_port, local_host, local_port):
    """SSH Remote Port Forwarding: VPS:remote_port -> local_host:local_port"""
    transport.request_port_forward("", remote_port)
    print(f"[+] 隧道已建立: VPS:{remote_port} -> {local_host}:{local_port}")
    print(f"[+] 外网访问: http://{VPS_IP}/youbaoplayer/")
    print("[+] 按 Ctrl+C 停止")
    while True:
        chan = transport.accept(1000)
        if chan is None:
            continue
        thr = threading.Thread(target=_handler, args=(chan, local_host, local_port))
        thr.setDaemon(True)
        thr.start()


def _handler(chan, host, port):
    sock = socket.socket()
    try:
        sock.connect((host, port))
    except Exception:
        chan.close()
        return
    while True:
        try:
            r, w, x = select.select([chan, sock], [], [])
            if chan in r:
                data = chan.recv(1024)
                if len(data) == 0:
                    break
                sock.send(data)
            if sock in r:
                data = sock.recv(1024)
                if len(data) == 0:
                    break
                chan.send(data)
        except Exception:
            break
    chan.close()
    sock.close()


while True:
    try:
        print(f"[*] 连接 SSH: {VPS_USER}@{VPS_IP}:22")
        ssh = paramiko.SSHClient()
        ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh.connect(
            VPS_IP,
            username=VPS_USER,
            password=SSH_PASS,
            timeout=15,
            banner_timeout=15,
        )
        transport = ssh.get_transport()
        tunnel_server(transport, REMOTE_PORT, "127.0.0.1", LOCAL_PORT)
    except KeyboardInterrupt:
        print("\n[*] 隧道已停止")
        break
    except Exception as e:
        print(f"[-] 连接断开: {e}")
        print("[*] 5秒后重连...")
        try:
            ssh.close()
        except Exception:
            pass
        time.sleep(5)
