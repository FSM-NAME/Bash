#!/bin/bash

# 检查系统类型并安装必要的工具
if [ -f /etc/debian_version ]; then
    # Debian-based system (Ubuntu, Debian)
    sudo apt-get update
    sudo apt-get install -y tar curl
elif [ -f /etc/redhat-release ]; then
    # Red Hat-based system (CentOS, Fedora)
    sudo yum install -y tar curl
else
    echo "Unsupported Linux distribution."
    exit 1
fi

# 设置变量
INSTALL_DIR="/etc/frp"
FRPC_BIN="frpc"
CONFIG_FILE="config.toml"
ARCHIVE_NAME="frp_latest.tar.gz"

# 创建安装目录
sudo mkdir -p $INSTALL_DIR

# 获取系统架构
ARCH=$(uname -m)
case $ARCH in
  x86_64)
    ARCH="amd64"
    ;;
  aarch64)
    ARCH="arm64"
    ;;
  armv7l)
    ARCH="arm"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# 获取最新版本的frp版本号
echo "Fetching the latest frp version..."
LATEST_VERSION=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

# 检查是否获取到版本号
if [ -z "$LATEST_VERSION" ]; then
    echo "Failed to fetch the latest frp version."
    exit 1
fi

# 构建下载链接
DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/$LATEST_VERSION/frp_${LATEST_VERSION:1}_linux_$ARCH.tar.gz"

# 下载最新版本的frp
echo "Downloading frp from $DOWNLOAD_URL..."
curl -L $DOWNLOAD_URL -o /tmp/$ARCHIVE_NAME

# 解压缩下载的文件
echo "Extracting frp archive..."
tar -xzvf /tmp/$ARCHIVE_NAME -C /tmp

# 查找解压后的目录
FRP_DIR=$(find /tmp -type d -name "frp_*_linux_$ARCH")
echo "Extracted to directory: $FRP_DIR"

# 检查解压后的目录内容
echo "Contents of extracted directory:"
ls -l $FRP_DIR

# 检查是否已经安装了frpc
if [ -f "$INSTALL_DIR/$FRPC_BIN" ]; then
    echo "Updating existing frpc installation..."
    sudo mv $FRP_DIR/$FRPC_BIN $INSTALL_DIR/$FRPC_BIN
else
    echo "Installing new frpc to $INSTALL_DIR..."
    sudo mv $FRP_DIR/$FRPC_BIN $INSTALL_DIR/$FRPC_BIN
    # 创建一个空白的config.toml文件
    sudo touch $INSTALL_DIR/$CONFIG_FILE
    echo "Created a blank config.toml at $INSTALL_DIR/$CONFIG_FILE"
fi

# 清理临时文件
echo "Cleaning up..."
rm -rf /tmp/$ARCHIVE_NAME
rm -rf $FRP_DIR

# 确认安装
if [ -f "$INSTALL_DIR/$FRPC_BIN" ]; then
    echo "frpc installed successfully at $INSTALL_DIR/$FRPC_BIN"
else
    echo "Installation failed."
fi
