# 故障案例

## 案例 #001：Nginx 502 — SELinux 网络权限限制

### 故障现象
- 浏览器访问若依显示 Nginx 50x 错误页
- 后端 Java 进程正常运行，`curl localhost:8080` 返回 HTTP 200
- Nginx 错误日志显示：`connect() to 127.0.0.1:8080 failed (13: Permission denied)`

### 故障原因
CentOS 默认 SELinux 策略中 `httpd_can_network_connect` 为 `off`，禁止 Nginx 主动连接本机其他端口。

### 排查过程
1. `ps -ef | grep ruoyi-admin.jar` 确认后端进程存在
2. `curl http://localhost:8080` 返回 200，排除后端故障
3. `tail -30 /var/log/nginx/error.log` 发现 `(13: Permission denied)`
4. 错误码 13 在 Linux 中表示 EACCES（权限不足），锁定 SELinux

### 解决方案
```bash
setsebool -P httpd_can_network_connect 1
systemctl reload nginx