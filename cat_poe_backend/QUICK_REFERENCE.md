# Catcoin Backend Deployment - Quick Reference

## 🐳 Docker Installation Options

### Option 1: Docker Deployment (Recommended)

**Pros:**
- ✅ Isolated environment
- ✅ Easy to manage (start/stop/update)
- ✅ Consistent across servers
- ✅ Includes PostgreSQL, Backend, and Nginx

**Install Docker on your server (Ubuntu/Debian):**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo apt-get install docker-compose-plugin

# Verify installation
docker --version
docker compose version
```

### Option 2: Traditional Deployment (No Docker)

Alternative deployment using:
- Systemd service for the backend
- PostgreSQL installed directly
- Nginx as reverse proxy
- Python virtual environment

---

## 📂 PostgreSQL Data Storage

### Default Storage Location

PostgreSQL data is stored in a **Docker named volume** on your server's local filesystem at:
```
/var/lib/docker/volumes/catcoin-backend_postgres_data/_data
```

### Custom Directory Mount (Optional)

To use a specific directory (e.g., `/opt/catcoin-data`), update line 14 in `docker-compose.prod.yml`:

**From:**
```yaml
volumes:
  - postgres_data:/var/lib/postgresql/data
```

**To:**
```yaml
volumes:
  - /opt/catcoin-data/postgres:/var/lib/postgresql/data
```

### Data Persistence

- ✅ Data survives container restarts
- ✅ Data persists when containers are removed
- ✅ Stored physically on server's disk

### Backup & Restore

**Backup database:**
```bash
docker exec catcoin_postgres pg_dump -U postgres catcoin_poe > backup_$(date +%Y%m%d).sql
```

**Restore from backup:**
```bash
cat backup_20231204.sql | docker exec -i catcoin_postgres psql -U postgres catcoin_poe
```

**Inspect volume location:**
```bash
docker volume inspect catcoin-backend_postgres_data
```

**Copy data to external location:**
```bash
docker run --rm \
  -v catcoin-backend_postgres_data:/from \
  -v /opt/catcoin-backup:/to \
  alpine cp -av /from /to
```

---

## 🚀 Quick Deployment Checklist

1. ✅ Install Docker & Docker Compose on server
2. ✅ Upload `catcoin-backend-deploy.tar.gz` to server
3. ✅ Extract and configure `.env.production`
4. ✅ Setup SSL certificates in `./ssl/` directory
5. ✅ Run `./deploy.sh`
6. ✅ Verify at `https://YOUR_API_DOMAIN/docs` (your hostname)

---

## 📞 Server details (fill in for your deployment)

- **Domain:** `YOUR_API_DOMAIN`
- **IP:** `YOUR_SERVER_IP`
- **Deployment path:** e.g. `/opt/catcoin-backend/` (your choice)

---

**For detailed instructions, see:** `DEPLOYMENT.md`
