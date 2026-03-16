#!/bin/bash
# Script to install the Chrome Native Messaging Host
HOST_NAME="com.inhausbrain.webmcp"
TARGET_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
mkdir -p "$TARGET_DIR"
cp extension/host/inhaus_webmcp.json "$TARGET_DIR/$HOST_NAME.json"
echo "Native messaging host installed."
