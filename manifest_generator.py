# -*- coding: utf-8 -*-
"""
生成 manifest.json - 扫描媒体目录并生成播放列表
"""
import os
import json
import sys

MEDIA_DIR = "media"
SUPPORTED_IMAGE = ('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp')
SUPPORTED_VIDEO = ('.mp4', '.avi', '.mov', '.wmv', '.flv', '.mkv')


def scan_media(directory):
    """递归扫描媒体目录"""
    items = []
    for root, dirs, files in os.walk(directory):
        # 跳过隐藏目录
        dirs[:] = [d for d in dirs if not d.startswith('.')]

        for filename in files:
            if filename.startswith('.'):
                continue
            ext = os.path.splitext(filename)[1].lower()
            if ext not in SUPPORTED_IMAGE and ext not in SUPPORTED_VIDEO:
                continue

            full_path = os.path.join(root, filename)
            rel_path = os.path.relpath(full_path, directory)
            # 使用正斜杠作为URL路径
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
        print("请创建 media 目录并将照片/视频放入其中")
        sys.exit(1)

    print(f"[*] 扫描媒体目录: {os.path.abspath(MEDIA_DIR)}")
    items = scan_media(MEDIA_DIR)
    print(f"[+] 找到 {len(items)} 个媒体文件")

    with open('manifest.json', 'w', encoding='utf-8') as f:
        json.dump(items, f, ensure_ascii=False, indent=2)

    print("[+] manifest.json 生成完成")


if __name__ == "__main__":
    main()
