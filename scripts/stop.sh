#!/bin/bash
# stop.sh - 停止若依后端服务

JAR_PATH="/home/ruoyi-admin.jar"

pid=$(ps -ef | grep $JAR_PATH | grep -v grep | awk '{print $2}')
if [ -z "$pid" ]; then
    echo "服务未运行"
    exit 1
fi

kill -15 $pid
echo "已发送停止信号，PID: $pid"

sleep 3
if ps -p $pid > /dev/null 2>&1; then
    echo "进程未退出，强制结束..."
    kill -9 $pid
fi
echo "服务已停止"