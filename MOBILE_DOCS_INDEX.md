# 📱 Mobile App Documentation Index

## Quick Navigation

### For Mobile App Developers

1. **[MOBILE-API.md](./MOBILE-API.md)** - **START HERE**
   - 📄 25KB | Complete API Reference
   - All endpoints with request/response examples
   - Authentication, Vessels, Trips, GPS, Marinas, Subscriptions
   - Code examples: React Native, Swift, Kotlin
   - Error handling and best practices
   - Rate limits and security

2. **[MOBILE_API_MONITORING.md](./MOBILE_API_MONITORING.md)**
   - 📄 10KB | API Monitoring Integration
   - **Required headers** for all API requests
   - How to integrate monitoring in your app
   - Debugging workflow
   - Code examples for header implementation

3. **[MOBILE_API_DOCUMENTATION.md](./MOBILE_API_DOCUMENTATION.md)**
   - 📄 5.5KB | Free Trial & Subscription System
   - User model subscription fields
   - Trial status checking logic
   - UI components needed
   - Test user credentials

### For Backend/Admin Team

4. **[MOBILE_MONITORING_SUMMARY.md](./MOBILE_MONITORING_SUMMARY.md)**
   - 📄 6KB | Admin Quick Reference
   - How to use monitoring dashboard
   - Debugging workflow for mobile issues
   - Feedback format examples
   - System overview

---

## Essential Information

### 🔗 API Base URLs
```
Production:  https://api.sudnokontrol.online/api
Development: https://api-dev.sudnokontrol.online/api
```

### 🎯 Monitoring Dashboard
```
Development: https://dev.sudnokontrol.online/api-monitor
(Admin access required: DPSU_ADMIN or GOVERNMENT_ADMIN)
```

### 📊 Required Headers for Mobile Apps
```javascript
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer <jwt_token>',  // when authenticated
  'X-App-Version': '1.0.0',               // Your app version
  'X-Platform': 'ios',                    // or 'android'
  'X-Device-Info': 'iPhone 15, iOS 17.5' // Device and OS
}
```

### 🔑 Key Endpoints

#### Authentication
- `POST /auth/register` - Register new user (auto-creates 30-day trial)
- `POST /auth/login` - Login (returns JWT token + user with subscription_status)
- `GET /auth/profile` - Get user profile

#### Vessels
- `GET /vessels/my` - Get my vessels
- `POST /vessels` - Add new vessel
- `GET /vessels/:id` - Get vessel details

#### Trips
- `POST /notifications` - Start trip (type: actual_departure)
- `POST /notifications` - End trip (type: actual_arrival)
- `GET /notifications/my` - Get trip history

#### GPS Tracking
- `POST /gps/log` - Log single GPS position
- `POST /gps/bulk-log` - Bulk log (offline sync)
- `GET /gps/vessel/:id/track` - Get vessel track

#### Subscriptions
- `GET /subscriptions/plans` - Get available plans
- `GET /subscriptions/my` - Get my subscription status
- `POST /subscriptions/subscribe` - Subscribe to plan

### 📱 User Object Structure
```json
{
  "id": "uuid",
  "phone": "+380501234567",
  "email": "user@example.com",
  "first_name": "Іван",
  "last_name": "Коваленко",
  "role": "ship_owner",
  "status": "verified",

  // Subscription fields
  "subscription_status": "trial",  // none|trial|active|expired|cancelled
  "trial_expires_at": "2025-10-26T10:02:15.498Z",
  "trial_days_remaining": 31
}
```

### ⚡ Rate Limits
- **Authentication**: 5 requests/minute per IP
- **GPS Logging**: 120 requests/minute per user
- **Standard API**: 60 requests/minute per user
- **Bulk Operations**: 10 requests/minute per user

### 🆘 Support Contacts

**Technical Support**
- Mobile: mobile-support@sudnokontrol.online
- Telegram: @sudno_support
- Hours: Пн-Пт 9:00-18:00 (UTC+2)

**Emergency**
- 24/7 Hotline: +380 800 123 456
- DPSU Emergency: 112

---

## Common Tasks

### Task: Setup New Mobile App Project
1. Read **MOBILE-API.md** sections:
   - Quick Start (base URL, auth header)
   - Authentication (register, login)
   - Error Handling
2. Implement required headers from **MOBILE_API_MONITORING.md**
3. Test with dev environment: https://api-dev.sudnokontrol.online

### Task: Implement Authentication
1. Read **MOBILE-API.md** → Authentication section
2. Read **MOBILE_API_DOCUMENTATION.md** → User model with subscription fields
3. Implement login/register flows
4. Handle subscription_status field

### Task: Implement Trip Tracking
1. Read **MOBILE-API.md** → Trip Management section
2. Read **MOBILE-API.md** → GPS Tracking section
3. Implement offline queue for GPS logs
4. Test with monitoring dashboard

### Task: Debug Mobile App Issue
1. Note exact time and user phone when issue occurred
2. Go to: https://dev.sudnokontrol.online/api-monitor
3. Filter logs by time/user/endpoint
4. Check error message and request/response data
5. Follow debugging workflow in **MOBILE_MONITORING_SUMMARY.md**

### Task: Implement Subscription System
1. Read **MOBILE_API_DOCUMENTATION.md** → Trial system
2. Read **MOBILE-API.md** → Subscriptions section
3. Implement trial checking logic
4. Add subscription UI components

---

## Documentation Versions

- **Last Updated**: October 1, 2025
- **API Version**: 1.1.0
- **Monitoring Dashboard**: v1.0
- **Mobile API Spec**: v2.0.0

---

## Quick Links

| Document | Size | Purpose |
|----------|------|---------|
| [MOBILE-API.md](./MOBILE-API.md) | 25KB | Complete API reference |
| [MOBILE_API_MONITORING.md](./MOBILE_API_MONITORING.md) | 10KB | Monitoring integration |
| [MOBILE_API_DOCUMENTATION.md](./MOBILE_API_DOCUMENTATION.md) | 5.5KB | Trial & subscription system |
| [MOBILE_MONITORING_SUMMARY.md](./MOBILE_MONITORING_SUMMARY.md) | 6KB | Admin reference |

---

*🇺🇦 SudnoKontrol Mobile API Documentation*
*Система контролю суден ДПСУ*
