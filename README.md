# 🐳 WordPress Docker Stack (Caddy + Redis + MariaDB)

A production-ready WordPress stack running on Docker with Caddy (auto SSL), Redis, and MariaDB.

---

## 🚀 Quick Deploy

```bash
git clone https://github.com/liondk/wordpress-docker.git
cd wordpress-docker
cp .env.example .env
# Edit .env to set domain, passwords, etc.
docker compose up -d --build
```

## VPS Resource Tuning

All main resource limits are configured in `.env`. The defaults in `.env.example` are safe for a 1GB RAM VPS.

The `.env.example` file includes ready-made VPS preset blocks. Keep only one block uncommented:

```env
MYSQL_INNODB_BUFFER_POOL_SIZE=128M
MYSQL_INNODB_LOG_FILE_SIZE=64M
MYSQL_MAX_CONNECTIONS=30
REDIS_MAXMEMORY=64mb
PHP_MEMORY_LIMIT=256M
PHP_FPM_MAX_CHILDREN=5
PHP_FPM_START_SERVERS=2
PHP_FPM_MIN_SPARE_SERVERS=1
PHP_FPM_MAX_SPARE_SERVERS=3
```

For 2GB or 4GB+ VPS, comment the 1GB block and uncomment the matching preset block.

## Backup And Restore

Use the management script for database and WordPress file backups:

```bash
chmod +x wp-manage.sh
./wp-manage.sh
```

Backups are stored in `./backup`. Restore actions require typing `RESTORE` and will overwrite current data.

Old backups are cleaned automatically after successful backups. Configure retention in `.env`:

```env
KEEP_BACKUPS=7
```
