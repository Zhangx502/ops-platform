# 企业办公系统运维与监控平台

## 项目简介
独立搭建一套包含 OA 系统、数据库主从复制、监控告警、日志集中管理的企业级运维环境，形成从部署、监控、日志到灾备的完整运维闭环。

## 技术栈

| 类别 | 技术 |
|------|------|
| 操作系统 | CentOS 7.9 |
| 应用服务 | 若依 OA（SpringBoot + Vue3）、Nginx 反向代理 |
| 数据库 | MySQL 5.7 主从复制 |
| 监控平台 | Prometheus + Grafana + Node Exporter |
| 日志平台 | Loki + Promtail |
| 脚本语言 | Shell |
| 安全 | firewalld、SELinux 策略 |

## 架构图

![运维平台架构图](arch.png)

## 服务器拓扑

| 服务器 | IP | 角色 | 核心组件 |
|--------|-----|------|----------|
| V1 | 192.168.205.10 | 应用服务器 | 若依 OA + Nginx + Node Exporter + Promtail |
| V2 | 192.168.205.11 | 主库 + 监控 | MySQL 主库 + Prometheus + Grafana + Node Exporter + Promtail |
| V3 | 192.168.205.12 | 从库 + 日志 | MySQL 从库 + Loki + Node Exporter + Promtail |

## 项目结构
ops-platform/
├── README.md
├── arch.png
├── .gitignore
├── scripts/
│ ├── start.sh
│ ├── stop.sh
│ ├── mysql_backup.sh
│ └── check_app.sh
├── configs/
│ ├── prometheus.yml
│ ├── loki-config.yaml
│ ├── promtail-config.yaml
│ └── nginx.conf
├── docs/
│ ├── deployment-guide.md
│ └── troubleshooting.md
└── screenshots/
├── grafana-dashboard.png
├── loki-logs.png
└── mysql-replication.png

## 核心功能
- 若依 OA 系统的部署与 Nginx 反向代理
- MySQL 主从复制，保障数据高可用
- Prometheus + Grafana 监控三台服务器 CPU/内存/磁盘
- Loki + Promtail 集中采集 Nginx 和应用日志
- Shell 脚本实现服务启停、数据库自动备份、故障自愈
- SELinux 策略排障（经典 502 故障案例）

## 快速开始
详细部署步骤请查看 [部署运维手册](docs/deployment-guide.md)

## 故障案例
- [Nginx 502 — SELinux 网络权限限制](docs/troubleshooting.md)

## 项目截图

| Grafana 监控 | Loki 日志 | MySQL 主从 |
|:---:|:---:|:---:|
| ![监控](screenshots/grafana-dashboard.png) | ![日志](screenshots/loki-logs.png) | ![主从](screenshots/mysql-replication.png) |

## 作者
ZX
