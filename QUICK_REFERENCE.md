# 🚀 SudnoKontrol Quick Reference

## 🌐 Environment URLs
- **Production**: https://sudnokontrol.online | https://api.sudnokontrol.online
- **Development**: https://dev.sudnokontrol.online | https://api-dev.sudnokontrol.online

## ⚡ Most Common Commands

### Check Everything
```bash
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh status
```

### Development Workflow
```bash
# 1. Work in development
cd /var/www/sudnokontrol.online/environments/development
# Make your changes...

# 2. Test at https://dev.sudnokontrol.online

# 3. Deploy to production
sudo rsync -av --exclude=node_modules --exclude=.next \
    /var/www/sudnokontrol.online/environments/development/frontend/ \
    /var/www/sudnokontrol.online/frontend/
sudo rsync -av --exclude=node_modules \
    /var/www/sudnokontrol.online/environments/development/backend/ \
    /var/www/sudnokontrol.online/backend/

# 4. Restart production
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh restart production
```

### Emergency Commands
```bash
# Restart everything
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh restart production
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh restart development

# View logs
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh logs production follow

# Backup database
sudo /var/www/sudnokontrol.online/scripts/manage-environments.sh backup production
```

## 📂 Key Directories
- **Production**: `/var/www/sudnokontrol.online/frontend` & `/var/www/sudnokontrol.online/backend`
- **Development**: `/var/www/sudnokontrol.online/environments/development/`
- **Scripts**: `/var/www/sudnokontrol.online/scripts/`

## 🔍 Health Checks
```bash
curl https://api.sudnokontrol.online/health
curl https://api-dev.sudnokontrol.online/health
```

---
📖 **Full Manual**: `/var/www/sudnokontrol.online/DEPLOYMENT_MANUAL.md`