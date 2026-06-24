#!/bin/bash
# ============================================
# 🐳 WordPress Docker Management Script
# Version: 1.3
# Author: LDK
# ============================================

set -Eeuo pipefail

# Config
BACKUP_DIR="./backup"
ENV_FILE=".env"

# Ensure env file exists. Docker Compose reads this file automatically.
if [ -f "$ENV_FILE" ]; then
    true
else
    echo "❌ Error: .env file not found!"
    exit 1
fi

KEEP_BACKUPS=$(grep -E '^KEEP_BACKUPS=' "$ENV_FILE" | tail -n 1 | cut -d '=' -f 2- | tr -d '"' | tr -d "'" || true)
KEEP_BACKUPS="${KEEP_BACKUPS:-7}"

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Colors
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
RED="\033[1;31m"
RESET="\033[0m"

# ============================================
# Functions
# ============================================

require_service_running() {
    SERVICE="$1"
    if ! docker compose ps --services --status running | grep -qx "$SERVICE"; then
        echo -e "${RED}❌ Error: service '$SERVICE' is not running.${RESET}"
        echo "Run: docker compose up -d"
        exit 1
    fi
}

require_db_env() {
    if ! docker compose exec -T db sh -c 'test -n "$MYSQL_DATABASE" && test -n "$MYSQL_USER" && test -n "$MYSQL_PASSWORD"'; then
        echo -e "${RED}❌ Error: MYSQL_DATABASE, MYSQL_USER, or MYSQL_PASSWORD is missing.${RESET}"
        exit 1
    fi
}

confirm_restore() {
    TARGET="$1"
    echo -e "${RED}⚠ Restore will overwrite current $TARGET data.${RESET}"
    read -r -p "Type RESTORE to continue: " CONFIRM
    if [ "$CONFIRM" != "RESTORE" ]; then
        echo "Restore cancelled."
        return 1
    fi
}

list_backups() {
    echo -e "${YELLOW}Available backups:${RESET}"
    find "$BACKUP_DIR" -maxdepth 1 -type f \( -name 'db_*.sql.gz' -o -name 'files_*.tar.gz' \) -printf '%f\n' | sort || true
}

cleanup_backups() {
    if ! [[ "$KEEP_BACKUPS" =~ ^[0-9]+$ ]] || [ "$KEEP_BACKUPS" -lt 1 ]; then
        echo -e "${RED}❌ Error: KEEP_BACKUPS must be a positive number.${RESET}"
        return 1
    fi

    echo -e "${YELLOW}→ Keeping latest $KEEP_BACKUPS database and file backups...${RESET}"
    find "$BACKUP_DIR" -maxdepth 1 -type f -name 'db_*.sql.gz' -printf '%T@ %p\n' | sort -rn | awk -v keep="$KEEP_BACKUPS" 'NR > keep {print $2}' | xargs -r rm -f
    find "$BACKUP_DIR" -maxdepth 1 -type f -name 'files_*.tar.gz' -printf '%T@ %p\n' | sort -rn | awk -v keep="$KEEP_BACKUPS" 'NR > keep {print $2}' | xargs -r rm -f
    echo -e "${GREEN}✅ Backup cleanup completed.${RESET}"
}

backup_db() {
  require_service_running db
  require_db_env

  echo -e "${YELLOW}→ Backing up database...${RESET}"
  FILE="$BACKUP_DIR/db_$(date +%Y%m%d_%H%M%S).sql.gz"
  
  if docker compose exec -T db sh -c 'mariadb-dump --single-transaction --quick --routines --triggers -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' | gzip -c > "$FILE"; then
    echo -e "${GREEN}✅ Database backup saved to:${RESET} $FILE"
    cleanup_backups
  else
    rm -f "$FILE"
    echo -e "${RED}❌ Database backup failed.${RESET}"
    return 1
  fi
}

backup_files() {
    echo -e "${YELLOW}→ Backing up WordPress files...${RESET}"
    FILE="$BACKUP_DIR/files_$(date +%Y%m%d_%H%M%S).tar.gz"

    if tar -czf "$FILE" wp_data; then
        echo -e "${GREEN}✅ Files backup saved to:${RESET} $FILE"
        cleanup_backups
    else
        rm -f "$FILE"
        echo -e "${RED}❌ Files backup failed.${RESET}"
        return 1
    fi
}

restore_db() {
  require_service_running db
  require_db_env

  list_backups
  read -p "Enter DB backup file name (e.g. db_20251017.sql.gz): " FILE
  FILE_PATH="$BACKUP_DIR/$FILE"
  
  if [ ! -f "$FILE_PATH" ]; then
    echo "❌ File not found: $FILE_PATH"
    exit 1
  fi

  confirm_restore "database" || return 0
   
  echo -e "${YELLOW}→ Restoring database from $FILE...${RESET}"

  docker compose stop wordpress wp-cron >/dev/null || true

  if gunzip -c "$FILE_PATH" | docker compose exec -T db sh -c 'mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"'; then
    echo -e "${GREEN}✅ Database restored successfully.${RESET}"
  else
    echo -e "${RED}❌ Database restore failed.${RESET}"
    docker compose start wordpress wp-cron >/dev/null || true
    return 1
  fi

  docker compose start wordpress wp-cron >/dev/null || true
}

restore_files() {
    list_backups
    read -p "Enter files backup name (e.g. files_20251017.tar.gz): " FILE
    FILE_PATH="$BACKUP_DIR/$FILE"
    if [ ! -f "$FILE_PATH" ]; then
        echo "❌ File not found: $FILE_PATH"
        exit 1
    fi

    confirm_restore "WordPress files" || return 0

    echo -e "${YELLOW}→ Restoring WordPress files...${RESET}"

    docker compose stop caddy wordpress wp-cron >/dev/null || true

    if tar -xzf "$FILE_PATH" -C .; then
        echo -e "${GREEN}✅ Files restored successfully.${RESET}"
    else
        echo -e "${RED}❌ Files restore failed.${RESET}"
        docker compose start wordpress wp-cron caddy >/dev/null || true
        return 1
    fi

    docker compose start wordpress wp-cron caddy >/dev/null || true
}

show_menu() {
    echo ""
    echo "============================================"
    echo "🧰 WordPress Docker Management Menu"
    echo "============================================"
    echo "1) Backup Database"
    echo "2) Backup Files"
    echo "3) Full Backup (DB + Files)"
    echo "4) Restore Database"
    echo "5) Restore Files"
    echo "6) Restart Stack"
    echo "7) Show Logs (WordPress)"
    echo "8) List Backups"
    echo "9) Cleanup Old Backups"
    echo "0) Exit"
    echo "--------------------------------------------"
}

restart_stack() {
    echo -e "${YELLOW}→ Restarting stack...${RESET}"
    docker compose restart
    echo -e "${GREEN}✅ Stack restarted.${RESET}"
}

show_logs() {
    echo -e "${YELLOW}→ Showing WordPress logs (Ctrl+C to exit)...${RESET}"
    docker compose logs -f wordpress
}

# ============================================
# Main menu
# ============================================

while true; do
    show_menu
    read -p "Choose an option [0-9]: " CHOICE
    case $CHOICE in
        1) backup_db ;;
        2) backup_files ;;
        3) backup_db && backup_files ;;
        4) restore_db ;;
        5) restore_files ;;
        6) restart_stack ;;
        7) show_logs ;;
        8) list_backups ;;
        9) cleanup_backups ;;
        0) echo "Bye 👋"; exit 0 ;;
        *) echo "Invalid option, try again." ;;
    esac
    echo ""
done
