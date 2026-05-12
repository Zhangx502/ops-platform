#!/bin/bash
# start.sh - 启动若依后端服务

APP_NAME="ruoyi-admin"
JAR_PATH="/home/ruoyi-admin.jar"
LOG_DIR="/home/logs"
LOG_PATH="$LOG_DIR/${APP_NAME}.log"

mkdir -p $LOG_DIR

pid=$(ps -ef | grep $JAR_PATH | grep -v grep | awk '{print $2}')
if [ -n "$pid" ]; then
    echo "$APP_NAME 已在运行，PID: $pid"
    exit 1
fi

nohup java -jar $JAR_PATH > $LOG_PATH 2>&1 &
echo "$APP_NAME 启动成功，PID: $!"