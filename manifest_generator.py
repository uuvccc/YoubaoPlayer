# -*- coding: utf-8 -*-
"""
生成 manifest.json - 扫描媒体目录并生成播放列表
优先读取 config.json 中的 media_dir 配置
"""
import os
import json
import sys

SUPPORTED_IMAGE = ('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp')
SUPPORTED_VIDEO = ('.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv')

SCRIPT_DIR = os.path.abspath(os.path.dirname(__file__))
CONFIG_PATH = os.path.join(SCRIPT_DIR, "config.json")

# 读取配置
if os.path.exists(CONFIG_PATH):
    with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
        config = json.load(f)
    MEDIA_DIR = config.get("media_dir", os.path.join(SCRIPT_DIR, "media"))
else:
    MEDIA_DIR = os.path.join(SCRIPT_DIR, "media")

if not os.path.isabs(MEDIA_DIR):
    MEDIA_DIR = os.path.join(SCRIPT_DIR, MEDIA_DIR)


def scan_media(directory):
    """递归扫描媒体目录"""
    items = []
    for root, dirs, files in os.walk(directory):
        dirs[:] = [d for d in dirs if not d.startswith('.')]

        for filename in files:
            if filename.startswith('.'):
                continue
            ext = os.path.splitext(filename)[1].lower()
            if ext not in SUPPORTED_IMAGE and ext not in SUPPORTED_VIDEO:
                continue

            full_path = os.path.join(root, filename)
            rel_path = os.path.relpath(full_path, directory)
            url_path = 'media/' + rel_path.replace('\\', '/')

            item = {
                "name": os.path.splitext(filename)[0],
                "path": url_path,
                "type": "image" if ext in SUPPORTED_IMAGE else "video"
            }
            items.append(item)

    return items


def main():
    if not os.path.exists(MEDIA_DIR):
        print(f"错误: 媒体目录 '{MEDIA_DIR}' 不存在")
        print("请在 config.json 中配置正确的 media_dir，或创建 media 目录")
        sys.exit(1)

    print(f"[*] 扫描媒体目录: {MEDIA_DIR}")
    items = scan_media(MEDIA_DIR)
    print(f"[+] 找到 {len(items)} 个媒体文件")

    output_path = os.path.join(SCRIPT_DIR, 'manifest.json')
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(items, f, ensure_ascii=False, indent=2)

    print(f"[+] {output_path} 生成完成")


if __name__ == "__main__":
    main()
