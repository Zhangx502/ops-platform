#!/bin/bash
# mysql_backup.sh - MySQL自动备份脚本

BACKUP_DIR="/backups/mysql"
DATE=$(date +%Y%m%d_%H%M%S)
DB_USER="root"
DB_PASSWORD="root"
DB_NAME="ry"

mkdir -p $BACKUP_DIR

mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME > "$BACKUP_DIR/backup_$DATE.sql"
gzip "$BACKUP_DIR/backup_$DATE.sql"
find "$BACKUP_DIR" -type f -mtime +7 -name "*.sql.gz" -exec rm {} \;

echo "备份完成：backup_$DATE.sql.gz"