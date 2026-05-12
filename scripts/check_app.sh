#!/bin/bash
# check_app.sh - 检测若依存活，挂了自动重启

pid=$(ps -ef | grep ruoyi-admin.jar | grep -v grep | awk '{print $2}')
if [ -z "$pid" ]; then
    echo "$(date)：服务已停止，正在重启..."
    /home/scripts/start.sh
fi