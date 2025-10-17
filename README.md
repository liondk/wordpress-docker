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
