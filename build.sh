#!/bin/bash
# MKey 编译 + 打包 + 签名
cd "$(dirname "$0")"
swift build -c release && cp .build/release/MKey MKey.app/Contents/MacOS/MKey && codesign --force --deep --sign - MKey.app && echo "✅ MKey.app 已就绪（已签名）"
