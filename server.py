# -*- coding: utf-8 -*-
"""
YoubaoPlayer Server
攸宝相册播放器 - 本地媒体文件HTTP服务器
支持：部分加载、随机播放、手机触摸适配
"""
import http.server
import socketserver
import os
import sys

PORT = 8900
PLAYER_DIR = os.path.abspath(os.path.dirname(__file__))
MEDIA_DIR = os.path.join(PLAYER_DIR, "media")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=PLAYER_DIR, **kwargs)

    def translate_path(self, path):
        if path.startswith('/media/'):
            from urllib.parse import unquote
            media_path = unquote(path[len('/media/'):])
            return os.path.join(MEDIA_DIR, media_path)
        return super().translate_path(path)

    def log_message(self, fmt, *args):
        print(f"[Youbao] {self.address_string()} {fmt % args}", flush=True)

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def main():
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("0.0.0.0", PORT), Handler) as httpd:
        print(f"YoubaoPlayer running: http://127.0.0.1:{PORT}/")
        print(f"  Media dir: {MEDIA_DIR}")
        httpd.serve_forever()


if __name__ == "__main__":
    main()
