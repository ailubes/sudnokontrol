# SUDNO-DPSU (СудноКонтроль)

Maritime vessel tracking and notification system for Ukraine's Border Guard Service.

## 🏗️ Architecture

This project consists of a Next.js frontend admin dashboard and a Node.js/Express backend API with PostgreSQL/PostGIS database.

### Environments

- **Production**: https://sudnokontrol.online | https://api.sudnokontrol.online
- **Development**: https://dev.sudnokontrol.online | https://api-dev.sudnokontrol.online

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- PostgreSQL with PostGIS extension
- Nginx (for production)

### Installation

```bash
# Clone repository
git clone <repository-url>
cd sudnokontrol.online

# Install dependencies
cd frontend && npm install --legacy-peer-deps
cd ../backend/backend && npm install

# Set up environment variables
cp .env.example .env.local  # Configure as needed

# Run development
npm run dev
```

## 🛠️ Development Workflow

See [DEPLOYMENT_MANUAL.md](./DEPLOYMENT_MANUAL.md) for comprehensive deployment instructions.

### Quick Commands

```bash
# Check environment status
sudo ./scripts/manage-environments.sh status

# Start development environment
sudo ./scripts/manage-environments.sh start development

# Deploy to production
sudo ./scripts/manage-environments.sh restart production
```

## 📂 Project Structure

```
├── frontend/                 # Next.js Admin Dashboard
├── backend/                  # Node.js/Express API
├── scripts/                  # Deployment & Management Scripts
├── environments/            # Multi-environment setup
│   └── development/        # Development environment
├── DEPLOYMENT_MANUAL.md    # Complete deployment guide
└── QUICK_REFERENCE.md      # Daily commands cheat sheet
```

## 🔧 Key Features

### User Roles
- **DPSU Admin**: Full system access and monitoring
- **Marina Admin**: Marina-specific vessel management
- **Ship Owner**: Vessel registration and notifications

### Core Functionality
- Vessel registration and management
- Movement notification system
- GPS tracking and logging
- Real-time vessel monitoring
- Email notifications to DPSU
- Owner management (vessels and marinas)

## 🗄️ Database Schema

PostgreSQL with PostGIS for geospatial data:
- `users` - User accounts with phone verification
- `vessels` - Vessel registrations
- `marinas` - Marina/port information
- `notifications` - Movement notifications
- `gps_logs` - GPS tracking data
- `subscriptions` - Service subscriptions

## 🌐 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `GET /api/auth/profile` - Get user profile

### Vessels
- `GET /api/vessels` - List vessels
- `POST /api/vessels` - Create vessel
- `PUT /api/vessels/:id` - Update vessel
- `DELETE /api/vessels/:id` - Delete vessel

### Notifications
- `GET /api/notifications` - List notifications
- `POST /api/notifications` - Create notification

### Owners
- `GET /api/owners/vessel-owners` - List vessel owners
- `GET /api/owners/marina-owners` - List marina owners
- `POST /api/owners` - Create owner
- `PUT /api/owners/:id` - Update owner

## 🔒 Security

- JWT authentication with auto-refresh
- Role-based access control
- CORS configuration
- Helmet security headers
- Rate limiting
- Input validation

## 🚢 Environment Variables

### Frontend
```env
NEXT_PUBLIC_API_BASE_URL=https://api.sudnokontrol.online/api
NEXT_PUBLIC_APP_NAME=SUDNO-DPSU Admin Dashboard
PORT=3000
```

### Backend
```env
NODE_ENV=production
PORT=3001
DB_HOST=localhost
DB_NAME=sudno_dpsu
JWT_SECRET=your-secret-key
DPSU_EMAIL=dpsu@sudnokontrol.online
```

## 🔧 Development

### Frontend Commands
```bash
cd frontend
npm run dev      # Development server
npm run build    # Production build
npm run start    # Production server
npm run lint     # Linting
```

### Backend Commands
```bash
cd backend/backend
npm run dev      # Development with nodemon
npm run build    # TypeScript compilation
npm start        # Production server
npm run db:migrate  # Database migrations
```

## 🚀 Deployment

The project supports multi-environment deployment:

1. **Development Environment**: Isolated testing environment
2. **Production Environment**: Live system for end users

Use the management scripts in `/scripts/` for deployment operations.

## 📊 Monitoring

- Health check endpoints: `/health`
- Application logs in `/tmp/`
- Nginx logs in `/var/log/nginx/`
- Database monitoring via PostgreSQL tools

## 📝 Contributing

1. Work in the development environment
2. Test thoroughly at https://dev.sudnokontrol.online
3. Deploy to production using management scripts
4. Monitor production logs after deployment

## 📄 License

This project is proprietary software for Ukraine's Border Guard Service.

## 🆘 Support

For technical issues:
1. Check the deployment manual: [DEPLOYMENT_MANUAL.md](./DEPLOYMENT_MANUAL.md)
2. Review application logs
3. Use the environment management scripts
4. Check the quick reference: [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)

---

**Built with ❤️ for Ukraine's Border Guard Service**