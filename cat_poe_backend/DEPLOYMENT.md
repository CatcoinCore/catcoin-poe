# Catcoin PoE Backend - Production Deployment Guide

## 🚀 Quick deployment (template)

Replace **`YOUR_API_DOMAIN`**, **`YOUR_SERVER_IP`**, and paths with your environment. **Do not** commit `.env` or TLS private keys.

### Prerequisites on Server
- Docker & Docker Compose installed
- TLS certificates for **your** API hostname
- Port 80, 443, 5432 available (or your chosen ports)

### Step 1: Prepare the Package

On your local machine:
```bash
cd path/to/cat_poe_backend

# Create deployment package (exclude unnecessary files)
tar -czf catcoin-backend.tar.gz \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='.idea' \
    --exclude='*.pyc' \
    --exclude='.env' \
    --exclude='venv' \
    .
```

### Step 2: Upload to Server

```bash
# Upload package (replace user/host)
scp catcoin-backend.tar.gz root@YOUR_SERVER_IP:/opt/

# SSH into server
ssh root@YOUR_SERVER_IP
```

### Step 3: Extract and Configure

```bash
cd /opt
mkdir -p catcoin-backend
tar -xzf catcoin-backend.tar.gz -C catcoin-backend
cd catcoin-backend

# Configure environment
cp .env.production.example .env.production
nano .env.production
```

**Update these values in `.env.production`:**
```bash
SECRET_KEY=$(openssl rand -hex 32)  # Generate new secret
DB_PASSWORD=$(openssl rand -base64 32)  # Generate strong password
# First boot only: create the `root` admin when that user does not exist (no defaults in repo).
ROOT_BOOTSTRAP_PASSWORD=your-strong-bootstrap-password
ROOT_BOOTSTRAP_EMAIL=admin@yourdomain.example
# Optional: public API URL for deploy/mirror script echoes and mirror_deploy health curl (no trailing slash).
# PUBLIC_API_BASE=https://YOUR_API_DOMAIN
```

### Step 4: Setup SSL Certificates

```bash
# Create SSL directory
mkdir -p ssl

# If you have Let's Encrypt certificates (replace hostname):
cp /etc/letsencrypt/live/YOUR_API_DOMAIN/fullchain.pem ssl/
cp /etc/letsencrypt/live/YOUR_API_DOMAIN/privkey.pem ssl/

# OR generate self-signed (for testing only):
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/privkey.pem \
    -out ssl/fullchain.pem \
    -subj "/CN=YOUR_API_DOMAIN"
```

### Step 5: Deploy

```bash
# Make deployment script executable
chmod +x deploy.sh

# Run deployment
./deploy.sh
```

### Step 6: Verify Deployment

```bash
# Check services
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs -f backend

# Test API
curl https://YOUR_API_DOMAIN/docs
```

## 📱 Update Flutter app

Point the client at your API using **`--dart-define=API_BASE_URL=https://YOUR_API_DOMAIN`** (see `cat_poe/docs/BUILD_RUNBOOK.md`) or change **`RELEASE_DEFAULT_API_BASE_URL`** in `cat_poe/lib/config/app_config.dart`. Do not hardcode production URLs in Dart without a define for forks.

Rebuild the app:
```bash
cd cat_poe
flutter build appbundle --release --dart-define=API_BASE_URL=https://YOUR_API_DOMAIN
```

## 🔧 Maintenance Commands

### View Logs
```bash
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f postgres
docker-compose -f docker-compose.prod.yml logs -f nginx
```

### Restart Services
```bash
docker-compose -f docker-compose.prod.yml restart backend
```

### Update Code
```bash
# Stop services
docker-compose -f docker-compose.prod.yml down

# Pull/upload new code
# ... (git pull or scp new files)

# Rebuild and restart
./deploy.sh
```

### Database Backup
```bash
docker exec catcoin_postgres pg_dump -U postgres catcoin_poe > backup_$(date +%Y%m%d).sql
```

### Database Restore
```bash
cat backup_20231204.sql | docker exec -i catcoin_postgres psql -U postgres catcoin_poe
```

## 🔒 Security Checklist

- [ ] SSL certificates installed and configured
- [ ] Strong SECRET_KEY generated
- [ ] Strong DB_PASSWORD set
- [ ] Firewall configured (only 80, 443 open)
- [ ] Database not exposed publicly
- [ ] Regular backups configured
- [ ] Root user password changed from default

## 🌐 DNS Configuration

Point your domain to the server (example **A** record):
```
Type: A
Name: api   # or @, depending on DNS
Value: YOUR_SERVER_IP
TTL: 3600
```

## 📊 Monitoring

Check service health:
```bash
# Backend health
curl https://YOUR_API_DOMAIN/health

# PostgreSQL status
docker exec catcoin_postgres pg_isready -U postgres
```

## 🐛 Troubleshooting

**Backend won't start:**
```bash
docker-compose -f docker-compose.prod.yml logs backend
```

**Database connection error:**
```bash
# Check if postgres is running
docker-compose -f docker-compose.prod.yml ps postgres

# Check database logs
docker-compose -f docker-compose.prod.yml logs postgres
```

**Nginx 502 Bad Gateway:**
```bash
# Check if backend is running
docker-compose -f docker-compose.prod.yml ps backend

# Check backend logs
docker-compose -f docker-compose.prod.yml logs backend
```

## 📞 Support

For issues, check:
1. Service logs
2. Environment variables
3. Database connectivity
4. SSL certificate validity
