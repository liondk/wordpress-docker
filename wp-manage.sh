#!/bin/bash
# ============================================
# 🐳 WordPress Docker Management Script
# Version: 1.2
# Author: LDK
# ============================================

# Config
BACKUP_DIR="./backup"
DATE=$(date +%Y%m%d_%H%M%S)
ENV_FILE=".env"

# Load env vars
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "❌ Error: .env file not found!"
    exit 1
fi

# Container names (adjust if needed)
DB_CONTAINER=$(docker ps --format '{{.Names}}' | grep db | head -n 1)
WP_CONTAINER=$(docker ps --format '{{.Names}}' | grep wordpress | head -n 1)

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

backup_db() {
    echo -e "${YELLOW}→ Backing up database...${RESET}"
    FILE="$BACKUP_DIR/db_${DATE}.sql.gz"
    docker exec "$DB_CONTAINER" sh -c "mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE" | gzip > "$FILE"
    echo -e "${GREEN}✅ Database backup saved to:${RESET} $FILE"
}

backup_files() {
    echo -e "${YELLOW}→ Backing up WordPress files...${RESET}"
    FILE="$BACKUP_DIR/files_${DATE}.tar.gz"
    tar -czf "$FILE" wp_data
    echo -e "${GREEN}✅ Files backup saved to:${RESET} $FILE"
}

restore_db() {
    read -p "Enter DB backup file name (e.g. db_20251017.sql.gz): " FILE
    FILE_PATH="$BACKUP_DIR/$FILE"
    if [ ! -f "$FILE_PATH" ]; then
        echo "❌ File not found: $FILE_PATH"
        exit 1
    fi
    echo -e "${YELLOW}→ Restoring database from $FILE...${RESET}"
    gunzip -c "$FILE_PATH" | docker exec -i "$DB_CONTAINER" \
        mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"
    echo -e "${GREEN}✅ Database restored successfully.${RESET}"
}

restore_files() {
    read -p "Enter files backup name (e.g. files_20251017.tar.gz): " FILE
    FILE_PATH="$BACKUP_DIR/$FILE"
    if [ ! -f "$FILE_PATH" ]; then
        echo "❌ File not found: $FILE_PATH"
        exit 1
    fi
    echo -e "${YELLOW}→ Restoring WordPress files...${RESET}"
    tar -xzf "$FILE_PATH" -C .
    echo -e "${GREEN}✅ Files restored successfully.${RESET}"
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
    read -p "Choose an option [0-7]: " CHOICE
    case $CHOICE in
        1) backup_db ;;
        2) backup_files ;;
        3) backup_db && backup_files ;;
        4) restore_db ;;
        5) restore_files ;;
        6) restart_stack ;;
        7) show_logs ;;
        0) echo "Bye 👋"; exit 0 ;;
        *) echo "Invalid option, try again." ;;
    esac
    echo ""
done
