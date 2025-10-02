# Development Service Management Guide

## Quick Reference

### Service Management Script

The **best and recommended way** to manage development services is using the dedicated management script:

```bash
/var/www/sudnokontrol.online/scripts/dev-services.sh COMMAND
```

## Commands

### Check Status
```bash
/var/www/sudnokontrol.online/scripts/dev-services.sh status
```

Shows the current status of both backend and frontend services.

### Restart All Services
```bash
/var/www/sudnokontrol.online/scripts/dev-services.sh restart
```

**This is the most commonly used command.** It safely stops and restarts both services.

### Start All Services
```bash
/var/www/sudnokontrol.online/scripts/dev-services.sh start
```

Starts both services if they're not running.

### Stop All Services
```bash
/var/www/sudnokontrol.online/scripts/dev-services.sh stop
```

Stops both services.

### Individual Service Control

#### Backend Only
```bash
/var/www/sudnokontrol.online/scripts/dev-services.sh backend restart
/var/www/sudnokontrol.online/scripts/dev-services.sh backend start
/var/www/sudnokontrol.online/scripts/dev-services.sh backend stop
/var/www/sudnokontrol.online/scripts/dev-services.sh backend logs
```

#### Frontend Only
```bash
/var/www/sudnokontrol.online/scripts/dev-services.sh frontend restart
/var/www/sudnokontrol.online/scripts/dev-services.sh frontend start
/var/www/sudnokontrol.online/scripts/dev-services.sh frontend stop
/var/www/sudnokontrol.online/scripts/dev-services.sh frontend logs
```

Aliases: `backend` can be `be`, `frontend` can be `fe`

### View Logs
```bash
# Both services
/var/www/sudnokontrol.online/scripts/dev-services.sh logs

# Backend only
/var/www/sudnokontrol.online/scripts/dev-services.sh logs backend

# Frontend only
/var/www/sudnokontrol.online/scripts/dev-services.sh logs frontend
```

Or directly:
```bash
tail -f /tmp/dev-backend.log
tail -f /tmp/dev-frontend.log
```

## Service Details

### Backend
- **Port**: 3030
- **URL**: https://api-dev.sudnokontrol.online
- **Health Check**: `curl http://localhost:3030/health`
- **Log**: `/tmp/dev-backend.log`
- **Working Directory**: `/var/www/sudnokontrol.online/environments/development/backend/backend`
- **Command**: `npm run dev` (nodemon with ts-node)

### Frontend
- **Port**: 8080
- **URL**: https://dev.sudnokontrol.online
- **Health Check**: `curl http://localhost:8080`
- **Log**: `/tmp/dev-frontend.log`
- **Working Directory**: `/var/www/sudnokontrol.online/environments/development/frontend`
- **Command**: `npx next dev -p 8080`

## Common Issues and Solutions

### Frontend Keeps Crashing

The frontend may appear to crash but it's actually just the Next.js dev server behavior. The process might spawn and then the health check completes, making it look like it crashed.

**Solution**: Always use the management script which handles this properly:
```bash
/var/www/sudnokontrol.online/scripts/dev-services.sh frontend restart
```

### Port Already in Use

If you get "EADDRINUSE" errors:

**Backend (port 3030)**:
```bash
lsof -ti:3030 | xargs kill -9
```

**Frontend (port 8080)**:
```bash
lsof -ti:8080 | xargs kill -9
```

Or use the management script which handles this automatically:
```bash
/var/www/sudnokontrol.online/scripts/dev-services.sh restart
```

### Service Won't Start

1. Check logs for errors:
   ```bash
   tail -50 /tmp/dev-backend.log
   tail -50 /tmp/dev-frontend.log
   ```

2. Verify you're in the correct directory:
   ```bash
   cd /var/www/sudnokontrol.online/environments/development/backend/backend  # Backend
   cd /var/www/sudnokontrol.online/environments/development/frontend         # Frontend
   ```

3. Check dependencies are installed:
   ```bash
   npm install  # In the appropriate directory
   ```

### Database Connection Issues

If backend fails with database errors:

1. Check PostgreSQL is running:
   ```bash
   systemctl status postgresql
   ```

2. Verify database exists:
   ```bash
   PGPASSWORD=sudno123postgres psql -h localhost -U postgres -l | grep sudno_dpsu_dev
   ```

3. Check .env file has correct credentials:
   ```bash
   cat /var/www/sudnokontrol.online/environments/development/backend/backend/.env | grep DB_
   ```

## Manual Service Management (Not Recommended)

If the management script fails, you can manage services manually:

### Backend Manual Start
```bash
cd /var/www/sudnokontrol.online/environments/development/backend/backend
nohup env NODE_ENV=development PORT=3030 DB_NAME=sudno_dpsu_dev DB_PASSWORD=sudno123postgres npm run dev > /tmp/dev-backend.log 2>&1 &
```

### Frontend Manual Start
```bash
cd /var/www/sudnokontrol.online/environments/development/frontend
nohup sh -c "PORT=8080 npx next dev -p 8080" > /tmp/dev-frontend.log 2>&1 &
```

### Manual Stop
```bash
# Kill by port
lsof -ti:3030 | xargs kill -9  # Backend
lsof -ti:8080 | xargs kill -9  # Frontend

# Or kill by process name
pkill -f "npm run dev"         # Backend
pkill -f "next dev"            # Frontend
```

## Verification

After starting services, verify they're running:

```bash
# Check status
/var/www/sudnokontrol.online/scripts/dev-services.sh status

# Test backend
curl http://localhost:3030/health

# Test frontend
curl http://localhost:8080

# Check processes
ps aux | grep -E "node.*3030|next.*8080" | grep -v grep

# Check ports
ss -tlnp | grep -E ":3030|:8080"
```

## Development Workflow

### Typical Restart Workflow
```bash
# 1. Check current status
/var/www/sudnokontrol.online/scripts/dev-services.sh status

# 2. Restart services after code changes
/var/www/sudnokontrol.online/scripts/dev-services.sh restart

# 3. Verify services started successfully
/var/www/sudnokontrol.online/scripts/dev-services.sh status

# 4. Check logs if needed
/var/www/sudnokontrol.online/scripts/dev-services.sh logs
```

### After Code Changes

**Backend changes**: Backend auto-restarts via nodemon, no manual restart needed

**Frontend changes**: Frontend hot-reloads automatically via Next.js

**Environment variable changes**: Restart required
```bash
/var/www/sudnokontrol.online/scripts/dev-services.sh backend restart  # If .env changed
```

**Dependency changes**: Restart required after `npm install`
```bash
/var/www/sudnokontrol.online/scripts/dev-services.sh restart
```

## URLs

- **Development Frontend**: https://dev.sudnokontrol.online
- **Development Backend API**: https://api-dev.sudnokontrol.online
- **Production Frontend**: https://sudnokontrol.online
- **Production Backend API**: https://api.sudnokontrol.online

## Remember

✅ **DO**: Use the management script (`dev-services.sh`)
✅ **DO**: Check logs when services fail
✅ **DO**: Verify status after operations

❌ **DON'T**: Manually run `npm run dev` in terminal (use script instead)
❌ **DON'T**: Leave orphaned processes running
❌ **DON'T**: Forget to check logs when debugging

## Quick Troubleshooting Checklist

1. ☐ Services running? → `dev-services.sh status`
2. ☐ Ports free? → `lsof -ti:3030` and `lsof -ti:8080`
3. ☐ Database up? → `systemctl status postgresql`
4. ☐ Check logs → `tail -f /tmp/dev-backend.log`
5. ☐ Try restart → `dev-services.sh restart`
6. ☐ Still failing? → Check error messages in logs
