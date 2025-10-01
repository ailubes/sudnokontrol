# Mobile API Monitoring System - Summary

## What Was Built

A complete API monitoring and logging system specifically designed to help track and debug mobile app (Expo) API requests.

## Components Created

### 1. Database (`api_logs` table)
- Captures every API request automatically
- Stores mobile-specific data: platform (iOS/Android), app version, device info
- Tracks user information, response times, errors, and full request/response data
- Indexed for fast querying

**Location**: `sudno_dpsu_dev` database

### 2. Backend Middleware
- **File**: `/backend/backend/src/middleware/simpleApiLogger.ts`
- Automatically logs all API requests (except `/health`)
- Captures custom mobile headers: `X-App-Version`, `X-Platform`, `X-Device-Info`
- Records errors, response times, and user context

### 3. Monitoring API Endpoints
- **File**: `/backend/backend/src/routes/api-monitor.ts`
- **Base URL**: `https://api-dev.sudnokontrol.online/api/api-monitor`

Endpoints:
- `GET /logs` - Get filtered API logs
- `GET /stats` - Get overall statistics
- `GET /mobile-app-stats` - Get mobile-specific stats
- `GET /logs/:id` - Get detailed log entry

### 4. Admin Dashboard
- **File**: `/frontend/src/app/api-monitor/page.tsx`
- **URL**: https://dev.sudnokontrol.online/api-monitor
- **Access**: Admin users only (DPSU_ADMIN, GOVERNMENT_ADMIN)

Features:
- Real-time log viewer with filtering
- Statistics dashboard (platform distribution, app versions, status codes)
- Mobile-specific analytics (active users, endpoint performance)
- Error tracking with detailed messages
- Auto-refresh capability
- CSV export functionality

## How to Use

### For You (Admin/Backend)

1. **Access Dashboard**:
   - Go to: https://dev.sudnokontrol.online/api-monitor
   - Login with admin credentials
   - View real-time API requests from mobile app

2. **Filter Logs**:
   - By platform (iOS/Android)
   - By status code (200, 400, 401, 404, 500)
   - By endpoint
   - By time range

3. **Analyze Errors**:
   - Go to "Errors" tab
   - See recent errors with full context
   - View common error patterns
   - Get user and device information

4. **Export Data**:
   - Click "Export CSV" button
   - Get all filtered logs in spreadsheet format

### For Mobile App Developer

1. **Add Required Headers** to all API requests:
   ```javascript
   headers: {
     'X-App-Version': '1.0.0',
     'X-Platform': 'ios', // or 'android'
     'X-Device-Info': 'iPhone 15, iOS 17.5'
   }
   ```

2. **See Documentation**:
   - Full integration guide: `/var/www/sudnokontrol.online/MOBILE_API_MONITORING.md`
   - Includes code examples for React Native/Expo, Swift, and Kotlin

## Debugging Workflow

When mobile app dev reports an issue:

1. Ask for:
   - Exact time the error occurred
   - User's phone number (if logged in)
   - What action they were performing

2. Check dashboard:
   - Filter by time range
   - Filter by user phone number
   - Look for errors (status 4xx or 5xx)

3. Analyze:
   - Check `error_message` field
   - Look at `request_body` to see what was sent
   - Check `response_time_ms` for performance issues
   - Verify `app_version` to ensure latest version

4. Provide feedback:
   - Exact error message
   - What data was sent vs what's expected
   - Suggested fix

## Real-Time Monitoring

The system tracks:
- **Request Volume**: Requests per minute
- **Response Times**: Average response time per endpoint
- **Error Rates**: Percentage of failed requests
- **Active Users**: Number of unique users in time period
- **Platform Distribution**: iOS vs Android usage
- **App Versions**: Which versions are being used

## Example Feedback Format

```
**Issue**: Login failing for mobile app

**Details**:
- Time: 2025-10-01 14:30:21
- Endpoint: POST /api/auth/login
- Platform: iOS
- App Version: 1.0.5
- Status: 401 Unauthorized
- Error: "Invalid phone number or password"
- Request: {"phone": "+380501234567", "password": "***"}

**Analysis**: Phone number format is correct, but user not found in database.
Check if user registration completed successfully.

**Suggested Fix**: Verify user exists in database before login attempt.
Add better error message to distinguish between "user not found" and "wrong password".
```

## Key Features for Mobile Debugging

✅ **Automatic Logging** - No code changes needed on backend
✅ **Mobile Headers** - Captures iOS/Android, app version, device info
✅ **Error Tracking** - Full error messages and stack traces
✅ **Performance Metrics** - Response time tracking per endpoint
✅ **User Context** - Links requests to specific users
✅ **Time-based Analysis** - Filter by exact time ranges
✅ **Export Capability** - Download logs for offline analysis
✅ **Real-time Updates** - Auto-refresh dashboard
✅ **Platform Filtering** - Separate iOS from Android issues

## Files Created/Modified

### Backend:
- `/backend/backend/src/middleware/simpleApiLogger.ts` - Enhanced with mobile headers
- `/backend/backend/src/routes/api-monitor.ts` - New monitoring API
- `/backend/backend/src/index.ts` - Registered new routes
- Database: Added `api_logs` table with mobile-specific columns

### Frontend:
- `/frontend/src/app/api-monitor/page.tsx` - New monitoring dashboard

### Documentation:
- `/var/www/sudnokontrol.online/MOBILE_API_MONITORING.md` - Complete guide
- `/var/www/sudnokontrol.online/MOBILE_MONITORING_SUMMARY.md` - This file

## Quick Access

- **Dashboard**: https://dev.sudnokontrol.online/api-monitor
- **API Docs**: /var/www/sudnokontrol.online/MOBILE_API_MONITORING.md
- **Database**: `api_logs` table in `sudno_dpsu_dev`
- **Backend Logs**: `tail -f /tmp/dev-backend.log`

## Next Steps

1. Share `MOBILE_API_MONITORING.md` with mobile app developer
2. Ask them to add the required headers to their API client
3. Test together - have them make a request, you check the dashboard
4. Monitor error patterns over next few days
5. Iterate on error messages based on what you see

## Related Documentation

This monitoring system works alongside existing mobile API documentation:

1. **MOBILE-API.md** (25KB)
   - Complete API reference for mobile app developers
   - All endpoints: Authentication, Vessels, Trips, GPS, Marinas, Subscriptions
   - Code examples in React Native, Swift, Kotlin
   - Error codes and handling
   - Best practices and rate limits

2. **MOBILE_API_DOCUMENTATION.md** (5.5KB)
   - Free trial system implementation
   - Subscription status fields in user object
   - Backend implementation details
   - Test user credentials
   - Database schema for subscriptions

3. **MOBILE_API_MONITORING.md** (10KB)
   - This document - monitoring system guide
   - Integration instructions for mobile devs
   - Debugging workflow
   - Dashboard usage

4. **MOBILE_MONITORING_SUMMARY.md** (6KB)
   - Quick reference for admins
   - System overview
   - Feedback format examples

## Key Information from Other Docs

### User Authentication Fields (from MOBILE_API_DOCUMENTATION.md)
After login, user object includes:
```json
{
  "subscription_status": "trial",
  "trial_expires_at": "2025-10-26T10:02:15.498Z",
  "trial_days_remaining": 31
}
```

### Rate Limits (from MOBILE-API.md)
- **Authentication**: 5 requests/minute per IP
- **GPS Logging**: 120 requests/minute per user
- **Standard API**: 60 requests/minute per user
- **Bulk Operations**: 10 requests/minute per user

### Key Endpoints (from MOBILE-API.md)
- Authentication: `POST /auth/login`, `POST /auth/register`
- Vessels: `GET /vessels/my`, `POST /vessels`
- Trips: `POST /notifications` (actual_departure/actual_arrival)
- GPS: `POST /gps/log`, `POST /gps/bulk-log`
- Marinas: `GET /marinas/nearby`
- Subscriptions: `GET /subscriptions/plans`, `POST /subscriptions/subscribe`

## Notes

- System is already running in development environment
- All requests are being logged automatically
- Dashboard requires admin login
- Logs are retained for 90 days
- No performance impact on API
- Works with existing free trial and subscription system
