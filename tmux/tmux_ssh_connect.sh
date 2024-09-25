#!/bin/bash

#tmux的快速多分屏

# 检查是否提供了 IP 文件和用户名
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ips_file> <username>"
    exit 1
fi

IPS_FILE="$1"
USERNAME="$2"

# 检查 IP 文件是否存在
if [ ! -f "$IPS_FILE" ]; then
    echo "File not found: $IPS_FILE"
    exit 1
fi

# 检查是否已经在 tmux 会话中
if [ -z "$TMUX" ]; then
    echo "This script must be run inside a tmux session."
    exit 1
fi

# 获取当前会话名
SESSION_NAME=$(tmux display-message -p '#S')

# 获取 IP 地址列表
IP_ADDRESSES=()
while IFS= read -r IP; do
    if [ -n "$IP" ]; then
        IP_ADDRESSES+=("$IP")
    fi
done < "$IPS_FILE"

# 获取 IP 数量
NUM_IPS=${#IP_ADDRESSES[@]}

# 检查是否至少有一个 IP 地址
if [ "$NUM_IPS" -eq 0 ]; then
    echo "No IP addresses found in the file."
    exit 1
fi

# 执行第一个 SSH 连接在第一个窗格中
tmux send-keys -t 0 "C-c" # 发送 Ctrl+C 来退出可能的复制模式
sleep 0.5
FIRST_IP=${IP_ADDRESSES[0]}
tmux send-keys -t 0 "ssh $USERNAME@$FIRST_IP" C-m

# 记录第一个窗格的 ID
FIRST_PANE_ID=$(tmux display-message -p '#{pane_id}')
echo "First pane ID: $FIRST_PANE_ID"

# 初始化分屏模式（1 = 横向，0 = 纵向）
MODE=1

# 创建其他窗格
for ((i=1; i<NUM_IPS; i++)); do
    IP=${IP_ADDRESSES[i]}

    # 查找最大可用空间的窗格
    MAX_PANE=$(tmux list-panes -F '#{pane_id} #{pane_width} #{pane_height}' | \
                sort -k2nr -k3nr | \
                awk '{print $1}' | \
                head -n1)

    if [ -z "$MAX_PANE" ]; then
        echo "No space available for new pane."
        exit 1
    fi

    # 选择最大空间的窗格
    tmux select-pane -t $MAX_PANE

    if [ "$MODE" -eq 1 ]; then
        # 横向分屏
        tmux split-window -h "ssh $USERNAME@$IP"
        MODE=0 # 切换到纵向分屏
    else
        # 纵向分屏
        tmux split-window -v "ssh $USERNAME@$IP"
        MODE=1 # 切换到横向分屏
    fi

    sleep 0.5 # 避免窗口重叠

    # 打印当前窗格状态
    echo "Current panes:"
    tmux list-panes
done

# 自动调整窗格布局
tmux select-layout -t $SESSION_NAME tiled

# 返回到第一个窗格
echo "Returning to pane ID: $FIRST_PANE_ID"
tmux select-pane -t $FIRST_PANE_ID

# 退出脚本
exit 0

