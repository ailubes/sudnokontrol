# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SUDNO-DPSU (СудноКонтроль) is a maritime vessel tracking and notification system for Ukraine's Border Guard Service. The system consists of a Next.js frontend admin dashboard and a Node.js/Express backend API with PostgreSQL/PostGIS database.

## Common Commands

### Frontend (Next.js Admin Dashboard)
```bash
# Development
cd frontend
npm install --legacy-peer-deps  # Install dependencies
npm run dev                      # Start dev server (port 3000)

# Production
npm run build                    # Build for production
npm run start                    # Start production server

# Code Quality
npm run lint                     # Run linter

# Utilities
npm run clean                    # Clean cache and node_modules
npm run fresh-install            # Clean reinstall
```

### Backend (Node.js API)
```bash
# Development
cd backend/backend
npm install                      # Install dependencies
npm run dev                      # Start dev server with nodemon

# Production
npm run build                    # Compile TypeScript
npm start                        # Start production server

# Database
npm run db:migrate               # Run database migrations
npm run db:seed                  # Seed database with test data
npm run populate:ports           # Populate ports data

# Code Quality
npm run lint                     # Run ESLint
npm test                         # Run tests
```

### Docker Operations
```bash
# Frontend Docker
cd frontend
./docker-run.sh dev              # Development mode
./docker-run.sh prod             # Production mode
./docker-run.sh stop             # Stop containers

# Backend Docker
cd backend
docker-compose up -d             # Start all services
docker-compose down              # Stop all services
```

## Architecture

### Frontend Structure
- **Framework**: Next.js 15 with App Router
- **UI**: shadcn/ui components with Tailwind CSS
- **Theme**: Northern Lights dark theme
- **State**: TanStack Query for server state
- **Auth**: JWT with auto-refresh mechanism
- **API Client**: Located in `frontend/src/lib/api.ts`
- **Routes**: App directory structure under `frontend/src/app/`

### Backend Structure
- **Framework**: Express with TypeScript
- **Database**: PostgreSQL with PostGIS extension
- **Auth**: JWT tokens with bcrypt password hashing
- **ORM**: Knex.js for database operations
- **Entry Point**: `backend/backend/src/index.ts`
- **Routes**: Modular route files in `backend/backend/src/routes/`
- **Controllers**: Business logic in `backend/backend/src/controllers/`

### API Base URLs
- Development: `http://localhost:3001/api`
- Production: `https://sudno-backend.enex.live/api`

## Key Features & User Roles

### Three Main User Roles:
1. **DPSU Admin**: Full system access, monitoring all vessels and notifications
2. **Marina Admin**: Manages marina-specific vessels and forwards notifications to DPSU
3. **Ship Owner**: Registers vessels, sends movement notifications

### Core Functionality:
- Vessel registration and management
- Movement notification system
- GPS tracking and logging
- Real-time vessel monitoring (planned)
- Email notifications to DPSU

## Database Schema

PostgreSQL with PostGIS for geospatial data:
- `users` - User accounts with phone verification
- `vessels` - Vessel registrations
- `marinas` - Marina/port information
- `notifications` - Movement notifications
- `gps_logs` - GPS tracking data
- `subscriptions` - Service subscriptions

## Environment Variables

### Frontend (.env.local)
```
NEXT_PUBLIC_API_BASE_URL=https://sudno-backend.enex.live/api
NEXT_PUBLIC_APP_NAME=SUDNO-DPSU Admin Dashboard
NEXT_PUBLIC_MAPBOX_ACCESS_TOKEN=<optional>
```

### Backend (.env)
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=sudno_dpsu
DB_USER=postgres
DB_PASSWORD=<password>
JWT_SECRET=<secret>
JWT_EXPIRES_IN=7d
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=<email>
SMTP_PASS=<password>
DPSU_EMAIL=<dpsu-email>
PORT=3001
NODE_ENV=development
```

## Important Notes

- Frontend uses `--legacy-peer-deps` flag for npm install due to dependency conflicts
- Backend requires PostgreSQL with PostGIS extension enabled
- JWT tokens auto-refresh in frontend (handled by auth context)
- All API endpoints require Bearer token authentication except auth routes
- GPS coordinates stored using PostGIS geometry type
- Frontend is configured to connect to production backend by default