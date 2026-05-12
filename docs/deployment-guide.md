一、项目概述
1.1 项目目标
独立搭建一套包含 OA 系统、数据库主从复制、监控告警、日志集中管理的企业级运维环境，形成从部署、监控、日志到灾备的完整运维闭环。

1.2 技术栈
类别	技术
操作系统	CentOS 7.9
应用服务	若依 OA（SpringBoot + Vue3）、Nginx 反向代理
数据库	MySQL 5.7 主从复制
监控平台	Prometheus + Grafana + Node Exporter
日志平台	Loki + Promtail
脚本语言	Shell
安全	firewalld、SELinux 策略

1.3 服务器架构
服务器	IP	角色	核心组件
V1	192.168.205.10	应用服务器	若依 OA（前端+后端）、Nginx、Node Exporter、Promtail
V2	192.168.205.11	数据库主库 + 监控中心	MySQL 主库、Prometheus、Grafana、Node Exporter、Promtail
V3	192.168.205.12	数据库从库 + 日志中心	MySQL 从库、Loki、Node Exporter、Promtail

1.4 架构图
![运维平台架构图](../arch.png)

二、环境规划
2.1 虚拟机配置
虚拟机	内存	硬盘	操作系统
V1	2GB	20GB	CentOS 7.9
V2	2GB	20GB	CentOS 7.9
V3	1GB	15GB	CentOS 7.9
2.2 端口规划
端口	服务	用途
80	Nginx	Web 入口
8080	若依后端	OA 系统后端
3306	MySQL	数据库
3000	Grafana	可视化仪表盘
9090	Prometheus	监控数据查询
9100	Node Exporter	节点指标采集
3100	Loki	日志存储查询
9080	Promtail	日志采集推送

三、核心部署步骤
3.1 基础环境安装（三台虚拟机）
安装 JDK 8
yum install -y java-1.8.0-openjdk-devel

安装 Nginx（第一台V1）
yum install -y epel-release
yum install -y nginx

安装 MySQL 5.7（第2，3）
wget https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
rpm -ivh mysql57-community-release-el7-11.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
yum install -y mysql-community-server

3.2 若依 OA 部署（第一台）
1.本地开发机打包若依前后端
2.前端 dist 文件拷贝至 /usr/share/nginx/html/
3.后端 jar 包上传至 /home/ruoyi-admin.jar
4.配置 Nginx 反向代理到 127.0.0.1:8080
5.Shell 脚本管理启停：start.sh、stop.sh

3.3 MySQL 主从复制（V2 主库 + V3 从库）
主库配置
[mysqld]
server-id=1
log-bin=mysql-bin

从库配置：
[mysqld]
server-id=2

复制用户创建及同步启动：

主库
CREATE USER 'repl_user'@'192.168.205.12' IDENTIFIED BY 'ReplPass123!';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'192.168.205.12';

从库
CHANGE MASTER TO
  MASTER_HOST='192.168.205.11',
  MASTER_USER='repl_user',
  MASTER_PASSWORD='ReplPass123!',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=154;
START SLAVE;

3.4 监控平台搭建
1.三台服务器安装 Node Exporter（端口 9100）
2.V2 安装 Prometheus（端口 9090），配置采集三台机器
3.V2 安装 Grafana（端口 3000），添加 Prometheus 数据源
4.导入 Node Exporter 仪表盘模板（ID：1860）

3.5 日志平台搭建（V3）
1.V3 安装 Loki（端口 3100），配置存储路径和 compactor
2.三台服务器安装 Promtail，配置推送地址为 http://192.168.205.12:3100/loki/api/v1/push
3.V2 Grafana 添加 Loki 数据源，使用 {job="nginx"} 查询日志

3.6 Shell 运维脚本
脚本		部署位置		功能
start.sh	V1	启动若依后端	检查是否重复运行
stop.sh	V1	停止若依		超时后强制结束
mysql_backup.sh	V2		定时备份 MySQL，压缩并清理 7 天前备份
check_app.sh	V1		每分钟检测若依存活，挂了自动重启

四、故障案例
Nginx 报502，浏览器访问若依顶部显示 Nginx 502 错误页，后端 Java 进程正常运行，curl localhost:8080 返回 HTTP 200，Nginx 错误日志显示：connect() to 127.0.0.1:8080 failed (13: Permission denied)
故障原因：CentOS 默认 SELinux 策略中 httpd_can_network_connect 为 off，禁止 Web 服务（Nginx）主动连接本机其他端口。
排查过程：
1.ps -ef | grep ruoyi-admin.jar 确认后端进程存在
2.curl http://localhost:8080 返回 200，排除后端故障
3.tail -30 /var/log/nginx/error.log 发现 (13: Permission denied)
4.错误码 13 在 Linux 中表示 EACCES（权限不足），锁定 SELinux
解决方案：
setsebool -P httpd_can_network_connect 1
systemctl reload nginx
遇到 Nginx 502 且后端正常时，优先检查 SELinux，不随意关闭安全策略，使用 setsebool 按需放行。

五、数据库迁移记录(实际使用的是V2不管)
若依原本使用 V1 本地 MySQL，将数据库迁移至 V2 主库。
（一）迁移步骤:
1.mysqldump -u root -proot ry > /tmp/ry_backup.sql（V1 导出）
2.scp 传输至 V2
3.V2 创建 ry 库并导入备份
4.修改若依 application-druid.yml 中数据库连接为 jdbc:mysql://192.168.205.11:3306/ry
重新打包部署，重启若依
（二）迁移后验证
关闭 V1 MySQL 服务，若依仍正常运行
V2 上查询 sys_user 表有若依用户数据
V3 从库同步正常，Slave_IO_Running 和 Slave_SQL_Running 均为 Yes

六、验证测试
验证项		方法					预期结果
若依可访问	浏览器打开 http://192.168.205.10		正常登录使用
主从同步		V3 执行 SHOW SLAVE STATUS\G		两个 Yes
监控面板		http://192.168.205.11:3000			三台服务器指标正常显示
日志查询		Grafana Explore → Loki → {job="nginx"}	显示 Nginx 访问日志
备份脚本		手动执行 mysql_backup.sh			/backups/mysql/ 生成 .sql.gz
存活检测		ps -ef | grep ruoyi-admin.jar			进程存在

七、日常运维使用命令
操作				命令
启动若依				/home/scripts/start.sh
停止若依				/home/scripts/stop.sh
检查若依进程			ps -ef | grep ruoyi-admin.jar | grep -v grep
检查主从状态			mysql -u root -proot -e "SHOW SLAVE STATUS\G" | grep Running
手动备份				/home/scripts/mysql_backup.sh
查看备份				ls -lh /backups/mysql/
查看 Nginx 错误			tail -30 /var/log/nginx/error.log
Prometheus Targets			http://192.168.205.11:9090/targets
Grafana 仪表盘			http://192.168.205.11:3000