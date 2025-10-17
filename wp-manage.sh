#!/bin/bash
# WordPress Docker Management Script
# Usage: ./wp-manage.sh [backup|restore|restart|logs]

BACKUP_DIR="./backup"
DATE=$(date +%Y%m%d_%H%M%S)
DB_CONTAINER="wordpress-docker-db-1"
WP_CONTAINER="wordpress-docker-wordpress-1"
DB_FILE="$BACKUP_DIR/db_$DATE.sql.gz"
FILES_FILE="$BACKUP_DIR/files_$DATE.tar.gz"
ENV_FILE=".env"

[ ! -d "$BACKUP_DIR" ] && mkdir -p "$BACKUP_DIR"

case "$1" in
  backup)
    echo "→ Backing up WordPress..."
    source "$ENV_FILE"
    docker exec $DB_CONTAINER sh -c "mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE" | gzip > "$DB_FILE"
    tar -czf "$FILES_FILE" wp_data
    echo "✅ Backup done: $BACKUP_DIR"
    ;;
  restore)
    echo "→ Restoring WordPress..."
    read -p "Enter backup date (e.g. 20251017): " D
    gunzip -c "$BACKUP_DIR/db_${D}.sql.gz" | docker exec -i $DB_CONTAINER \
      mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"
    tar -xzf "$BACKUP_DIR/files_${D}.tar.gz" -C .
    echo "✅ Restore done."
    ;;
  restart)
    docker compose restart
    ;;
  logs)
    docker compose logs -f wordpress
    ;;
  *)
    echo "Usage: ./wp-manage.sh [backup|restore|restart|logs]"
    ;;
esac
