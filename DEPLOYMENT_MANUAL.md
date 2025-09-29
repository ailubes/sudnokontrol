# SudnoKontrol Multi-Environment Deployment Manual

## 🏗️ Architecture Overview

Your SudnoKontrol project now runs in two separate environments on the same server:

### Production Environment
- **Frontend**: https://sudnokontrol.online (port 3000)
- **API**: https://api.sudnokontrol.online (port 6000)
- **Database**: `sudno_dpsu`
- **Purpose**: Live system for end users

### Development Environment
- **Frontend**: https://dev.sudnokontrol.online (port 8080)
- **API**: https://api-dev.sudnokontrol.online (port 3030)
- **Database**: `sudno_dpsu_dev`
- **Purpose**: Testing new features and changes

---

## 🔄 Development Workflow

### 1. Making Changes

#### Option A: Direct Development on Server
```bash
# Navigate to development environment
cd /var/www/sudnokontrol.online/environments/development

# Make your changes to frontend or backend
# Edit files in:
# - frontend/ (for UI changes)
# - backend/backend/ (for API changes)

# The development server will auto-reload with your changes
```

#### Option B: Local Development + Sync
```bash
# Work locally on your machine, then sync to server
# Upload your changes to the development environment
rsync -avz ./your-changes/ root@your-server:/var/www/sudnokontrol.online/environments/development/
```

### 2. Testing Changes

1. **Test in Development**: https://dev.sudnokontrol.online
2. **Check API**: https://api-dev.sudnokontrol.online/health
3. **Review logs**:
   ```bash
   sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh logs dev follow
   ```

### 3. Deploying to Production

When your changes are tested and ready:

```bash
# 1. Copy changes from development to production
sudo rsync -av --exclude=node_modules --exclude=.next --exclude=dist \
    /var/www/sudnokontrol.online/environments/development/frontend/ \
    /var/www/sudnokontrol.online/frontend/

sudo rsync -av --exclude=node_modules --exclude=dist \
    /var/www/sudnokontrol.online/environments/development/backend/ \
    /var/www/sudnokontrol.online/backend/

# 2. Rebuild and restart production
cd /var/www/sudnokontrol.online/frontend
sudo npm run build
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh restart production
```

---

## 🛠️ Management Commands

### Environment Manager Script

The main management tool is located at:
`/var/www/sudnokontrol.online/scripts/manage-environments.sh`

#### Check Status
```bash
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh status
```

#### Start Environments
```bash
# Start production
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh start production

# Start development
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh start development

# Start both
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh start all
```

#### Stop Environments
```bash
# Stop specific environment
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh stop production

# Stop all environments
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh stop all
```

#### Restart Environments
```bash
# Restart production
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh restart production

# Restart development
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh restart development
```

#### View Logs
```bash
# View recent logs
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh logs production
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh logs development

# Follow logs in real-time
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh logs production follow
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh logs development follow
```

#### Backup Database
```bash
# Backup production database
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh backup production

# Backup development database
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh backup development
```

---

## 📂 Directory Structure

```
/var/www/sudnokontrol.online/
├── frontend/                     # 🏭 Production Frontend
├── backend/                      # 🏭 Production Backend
├── environments/
│   └── development/
│       ├── frontend/             # 🛠️ Development Frontend
│       └── backend/              # 🛠️ Development Backend
├── scripts/
│   ├── deploy-development.sh     # Development deployment script
│   └── manage-environments.sh    # Main management script
└── DEPLOYMENT_MANUAL.md          # This manual
```

---

## ⚙️ Configuration Files

### Frontend Environment Files

**Production**: `/var/www/sudnokontrol.online/frontend/.env.local`
```env
NEXT_PUBLIC_API_BASE_URL=http://localhost:3030/api
NEXT_PUBLIC_APP_NAME=SudnoKontrol Admin Dashboard
PORT=8080
```

**Development**: `/var/www/sudnokontrol.online/environments/development/frontend/.env.local`
```env
NEXT_PUBLIC_API_BASE_URL=https://api-dev.sudnokontrol.online/api
NEXT_PUBLIC_APP_NAME=SudnoKontrol Admin Dashboard (Development)
PORT=8080
NODE_ENV=development
```

### Backend Environment Files

**Production**: `/var/www/sudnokontrol.online/backend/backend/.env`
- `NODE_ENV=production`
- `PORT=3030`
- `DB_NAME=sudno_dpsu`
- `API_BASE_URL=https://api.sudnokontrol.online`

**Development**: `/var/www/sudnokontrol.online/environments/development/backend/backend/.env`
- `NODE_ENV=development`
- `PORT=3030`
- `DB_NAME=sudno_dpsu_dev`
- `API_BASE_URL=https://api-dev.sudnokontrol.online`

---

## 🗄️ Database Management

### Databases
- **Production**: `sudno_dpsu`
- **Development**: `sudno_dpsu_dev`

### Common Database Tasks

#### Connect to Database
```bash
# Production database
PGPASSWORD=sudno123postgres psql -h localhost -U postgres -d sudno_dpsu

# Development database
PGPASSWORD=sudno123postgres psql -h localhost -U postgres -d sudno_dpsu_dev
```

#### Run Migrations
```bash
# Production migrations
cd /var/www/sudnokontrol.online/backend/backend
DB_PASSWORD=sudno123postgres npx knex migrate:latest --env production

# Development migrations
cd /var/www/sudnokontrol.online/environments/development/backend/backend
DB_PASSWORD=sudno123postgres npx knex migrate:latest --env development
```

#### Sync Development Database with Production
```bash
# Backup production and restore to development
PGPASSWORD=sudno123postgres pg_dump -h localhost -U postgres sudno_dpsu > /tmp/prod_backup.sql
PGPASSWORD=sudno123postgres dropdb -h localhost -U postgres sudno_dpsu_dev
PGPASSWORD=sudno123postgres createdb -h localhost -U postgres sudno_dpsu_dev
PGPASSWORD=sudno123postgres psql -h localhost -U postgres -d sudno_dpsu_dev < /tmp/prod_backup.sql
```

---

## 🚀 Common Workflows

### 1. Adding a New Feature

```bash
# 1. Start development environment if not running
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh start development

# 2. Make changes in development environment
cd /var/www/sudnokontrol.online/environments/development

# 3. Test changes at https://dev.sudnokontrol.online

# 4. When satisfied, deploy to production
sudo rsync -av --exclude=node_modules --exclude=.next \
    /var/www/sudnokontrol.online/environments/development/frontend/ \
    /var/www/sudnokontrol.online/frontend/

sudo rsync -av --exclude=node_modules \
    /var/www/sudnokontrol.online/environments/development/backend/ \
    /var/www/sudnokontrol.online/backend/

# 5. Restart production
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh restart production
```

### 2. Debugging Issues

```bash
# 1. Check environment status
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh status

# 2. View logs
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh logs production follow

# 3. Check specific services
curl https://api.sudnokontrol.online/health
curl https://sudnokontrol.online

# 4. Restart if needed
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh restart production
```

### 3. Database Changes

```bash
# 1. Test migration in development
cd /var/www/sudnokontrol.online/environments/development/backend/backend
DB_PASSWORD=sudno123postgres npx knex migrate:latest --env development

# 2. Test application with new schema
# Visit https://dev.sudnokontrol.online

# 3. Apply to production
cd /var/www/sudnokontrol.online/backend/backend
DB_PASSWORD=sudno123postgres npx knex migrate:latest --env production

# 4. Restart production backend
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh restart production
```

### 4. Emergency Rollback

```bash
# 1. Stop problematic environment
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh stop production

# 2. Restore from backup if needed
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh backup production

# 3. Revert code changes (manual)
# 4. Restart
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh start production
```

---

## 🔒 Security Considerations

### SSL Certificates
- Automatically renewed by Let's Encrypt
- Certificates located in `/etc/letsencrypt/live/`

### Nginx Configuration
- Production: `/etc/nginx/sites-available/sudnokontrol.online`
- Development: `/etc/nginx/sites-available/dev.sudnokontrol.online`
- API Production: `/etc/nginx/sites-available/api.sudnokontrol.online`
- API Development: `/etc/nginx/sites-available/api-dev.sudnokontrol.online`

### Environment Variables
- Never commit sensitive data to git
- Keep production secrets separate from development

---

## 📊 Monitoring

### Log Locations
- **Production Frontend**: `/tmp/prod-frontend.log`
- **Production Backend**: `/tmp/prod-backend.log`
- **Development Frontend**: `/tmp/dev-frontend.log`
- **Development Backend**: `/tmp/dev-backend.log`
- **Nginx Access**: `/var/log/nginx/access.log`
- **Nginx Error**: `/var/log/nginx/error.log`

### Health Checks
- Production API: `https://api.sudnokontrol.online/health`
- Development API: `https://api-dev.sudnokontrol.online/health`

### Process Monitoring
```bash
# Check running processes
ps aux | grep -E "(PORT=3000|PORT=6000|PORT=8080|PORT=3030)"

# Check port usage
netstat -tlnp | grep -E "(3000|6000|8080|3030)"
```

---

## 🆘 Troubleshooting

### Common Issues

#### Port Already in Use
```bash
# Find and kill process using port
sudo lsof -i :3000
sudo kill -9 <PID>
```

#### Database Connection Issues
```bash
# Check PostgreSQL status
sudo systemctl status postgresql

# Restart PostgreSQL
sudo systemctl restart postgresql
```

#### Nginx Issues
```bash
# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx

# Check nginx status
sudo systemctl status nginx
```

#### SSL Certificate Issues
```bash
# Renew certificates
sudo certbot renew

# Check certificate expiry
sudo certbot certificates
```

### Getting Help

1. **Check logs first**: Always start with the logs
2. **Verify status**: Use the status command to see what's running
3. **Test connectivity**: Use curl to test endpoints
4. **Check processes**: Verify processes are running on correct ports

---

## 📝 Quick Reference

### URLs
- **Production Frontend**: https://sudnokontrol.online
- **Production API**: https://api.sudnokontrol.online
- **Development Frontend**: https://dev.sudnokontrol.online
- **Development API**: https://api-dev.sudnokontrol.online

### Ports
- **Production Frontend**: 3000 (internal)
- **Production Backend**: 6000 (internal)
- **Development Frontend**: 8080 (internal)
- **Development Backend**: 3030 (internal)

### Key Commands
```bash
# Status check
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh status

# Start development
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh start development

# Deploy development changes to production
sudo rsync -av --exclude=node_modules /var/www/sudnokontrol.online/environments/development/ /var/www/sudnokontrol.online/

# Restart production
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh restart production
```

---

## 🎯 Best Practices

1. **Always test in development first**
2. **Use the management scripts instead of manual commands**
3. **Monitor logs during deployments**
4. **Backup production database before major changes**
5. **Keep development database in sync with production schema**
6. **Use descriptive commit messages if using git**
7. **Document any custom configuration changes**

---

*This manual was generated as part of the multi-environment setup on $(date). Keep it updated as your workflow evolves.*