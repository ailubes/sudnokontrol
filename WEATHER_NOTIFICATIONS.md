# Weather Notification System

## Overview

The weather notification system automatically sends weather alerts to users based on their regional access. It uses the OpenWeather API to fetch real-time weather data for Ukrainian coastal regions.

## Features

- **Multi-region support**: 6 Ukrainian coastal regions
- **Multi-level alerts**: Low, Medium, High, Critical severity
- **Automatic filtering**: Only sends notifications for significant weather events
- **Regional targeting**: Users receive alerts only for their accessible regions
- **Ukrainian language**: All messages in Ukrainian

## Supported Regions

1. **Одеська** (Odesa) - lat: 46.4825, lon: 30.7233
2. **Миколаївська** (Mykolaiv) - lat: 46.9750, lon: 31.9946
3. **Херсонська** (Kherson) - lat: 46.6354, lon: 32.6169
4. **Запорізька** (Zaporizhzhia) - lat: 47.8388, lon: 35.1396
5. **Донецька** (Mariupol) - lat: 47.0945, lon: 37.5432
6. **Автономна Республіка Крим** (Simferopol) - lat: 44.9572, lon: 34.1108

## Alert Thresholds

### Wind Alerts
- **Medium** (🌬️): Wind speed > 25 km/h
- **High** (⚠️): Wind speed > 40 km/h
- **Critical** (⚠️ КРИТИЧНО): Wind speed > 60 km/h

### Visibility Alerts
- **Medium** (🌫️): Visibility < 5 km
- **High** (🌫️ УВАГА): Visibility < 1 km

### Temperature Alerts
- **Medium** (❄️): Temperature < 0°C (ice risk)

### Storm Alerts
- **High** (⛈️ УВАГА): Storm keywords detected (гроза, шторм, злива, сильн)

## API Endpoints

### User Endpoints (All Authenticated Users)

#### Get Available Regions
```bash
GET /api/notifications/weather/regions
```

**Response:**
```json
{
  "regions": [
    "Одеська",
    "Миколаївська",
    "Херсонська",
    "Запорізька",
    "Донецька",
    "Автономна Республіка Крим"
  ]
}
```

#### Get Weather for Region
```bash
GET /api/notifications/weather/:region
```

**Example:**
```bash
GET /api/notifications/weather/Одеська
```

**Response:**
```json
{
  "weather": {
    "region": "Одеська",
    "city": "Odesa",
    "temperature": 18,
    "feels_like": 16,
    "description": "ясно",
    "wind_speed": 32,
    "wind_direction": 180,
    "humidity": 65,
    "pressure": 1013,
    "visibility": 10,
    "timestamp": "2025-10-02T08:50:00.000Z"
  },
  "alerts": [
    {
      "region": "Одеська",
      "severity": "medium",
      "type": "wind",
      "message": "🌬️ Помірний вітер 32 км/год. Рекомендується обережність."
    }
  ]
}
```

#### Get Weather Summary for Region
```bash
GET /api/notifications/weather/:region/summary
```

**Response:**
```json
{
  "region": "Одеська",
  "summary": "🌊 Погода в регіоні Одеська (Odesa)\n\n🌡️ Температура: 18°C (відчувається як 16°C)\n☁️ Опис: ясно\n💨 Вітер: 32 км/год\n👁️ Видимість: 10 км\n💧 Вологість: 65%\n\n⚠️ ПОПЕРЕДЖЕННЯ:\n🌬️ Помірний вітер 32 км/год. Рекомендується обережність.\n"
}
```

### Admin Endpoints

#### Send Weather Notifications (Manual Trigger)
```bash
POST /api/notifications/weather/send
Authorization: Bearer <admin-token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "regions": ["Одеська", "Миколаївська"],  // Optional - defaults to all regions
  "severityThreshold": "medium"              // Optional - low|medium|high|critical
}
```

**Response:**
```json
{
  "message": "Weather notifications processed",
  "results": [
    {
      "region": "Одеська",
      "status": "sent",
      "alertCount": 2,
      "userCount": 15,
      "sentCount": 15,
      "highestSeverity": "medium"
    },
    {
      "region": "Миколаївська",
      "status": "skipped",
      "message": "No significant weather alerts"
    }
  ]
}
```

## Automated Scheduling

### Cron Job Setup

To automatically send weather notifications, set up a cron job using the provided script:

```bash
# Edit crontab
crontab -e

# Add one of the following schedules:

# Every 6 hours (recommended for weather updates)
0 */6 * * * /var/www/sudnokontrol.online/scripts/send-weather-notifications.sh

# Every 3 hours (more frequent updates)
0 */3 * * * /var/www/sudnokontrol.online/scripts/send-weather-notifications.sh

# Twice daily (morning and evening)
0 6,18 * * * /var/www/sudnokontrol.online/scripts/send-weather-notifications.sh

# Only during business hours (8 AM - 8 PM every 2 hours)
0 8-20/2 * * * /var/www/sudnokontrol.online/scripts/send-weather-notifications.sh
```

### Script Configuration

Set environment variables for the cron script:

```bash
# In /etc/environment or in crontab
WEATHER_CRON_PASSWORD=<admin-password>
API_URL=https://api-dev.sudnokontrol.online/api/notifications/weather/send
SEVERITY_THRESHOLD=medium
```

### View Logs

```bash
tail -f /var/log/weather-notifications.log
```

## Environment Variables

### Backend (.env)

```bash
# OpenWeather API Key (required)
OPENWEATHER_API_KEY=your_api_key_here
```

**Get API Key:**
1. Visit https://openweathermap.org/api
2. Sign up for a free account
3. Generate an API key
4. Add to backend `.env` file

## User Regional Access

Users receive weather notifications based on their `regional_access` field in the database:

```sql
-- Example: User with access to Odesa and Mykolaiv regions
UPDATE users
SET regional_access = '["Одеська", "Миколаївська"]'::jsonb
WHERE id = 'user-uuid';
```

## Database Schema

Weather notifications are stored in the `notifications` table:

```sql
-- Weather notification record
INSERT INTO notifications (
  user_id,
  type,              -- 'weather_alert'
  status,            -- 'sent'
  comments,          -- Full weather summary
  created_at,
  updated_at
) VALUES (
  'user-uuid',
  'weather_alert',
  'sent',
  '🌊 Погода в регіоні Одеська...',
  NOW(),
  NOW()
);
```

## Testing

### Manual Test via API

```bash
# 1. Login as admin
curl -X POST https://api-dev.sudnokontrol.online/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"+380999999999","password":"yourpassword"}'

# 2. Get weather for region
curl https://api-dev.sudnokontrol.online/api/notifications/weather/Одеська \
  -H "Authorization: Bearer <token>"

# 3. Send weather notifications
curl -X POST https://api-dev.sudnokontrol.online/api/notifications/weather/send \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"severityThreshold":"medium"}'
```

### Test Cron Script

```bash
# Set password temporarily
export WEATHER_CRON_PASSWORD="yourpassword"

# Run script manually
/var/www/sudnokontrol.online/scripts/send-weather-notifications.sh

# Check logs
tail -f /var/log/weather-notifications.log
```

## Severity Threshold Guide

- **low**: Send notifications for all weather conditions (including favorable)
- **medium**: Send for moderate alerts and above (wind >25 km/h, visibility <5km, etc.)
- **high**: Send only for dangerous conditions (wind >40 km/h, visibility <1km, storms)
- **critical**: Send only for critical conditions (wind >60 km/h)

**Recommended setting:** `medium` - balances informativeness with avoiding notification fatigue

## Future Enhancements

### Planned Features
- [ ] SMS notifications via Twilio/Vonage
- [ ] Email notifications with weather maps
- [ ] Viber/WhatsApp integration
- [ ] Mobile push notifications
- [ ] Weather forecast (next 24/48 hours)
- [ ] Marine-specific data (wave height, sea temperature, tides)
- [ ] Historical weather data tracking
- [ ] Custom alert thresholds per user
- [ ] Weather warnings from UKRHMC (Ukrainian Hydrometeorological Center)

### Integration Ideas
- Display current weather on vessel dashboard
- Show weather alerts on map markers
- Include weather data in trip planning
- Automatic trip warnings based on conditions
- Weather-based marina recommendations

## Troubleshooting

### No Notifications Sent

1. **Check OpenWeather API Key:**
   ```bash
   curl "https://api.openweathermap.org/data/2.5/weather?lat=46.4825&lon=30.7233&appid=YOUR_KEY"
   ```

2. **Check User Regional Access:**
   ```sql
   SELECT id, phone, regional_access FROM users WHERE regional_access IS NOT NULL;
   ```

3. **Test Weather Service:**
   ```bash
   # In backend directory
   node -e "const {weatherService} = require('./dist/services/weatherService'); weatherService.getWeatherByRegion('Одеська').then(console.log);"
   ```

### API Key Issues

If using demo/free tier:
- Rate limit: 60 calls/minute, 1,000,000 calls/month
- For production, upgrade to paid plan
- Consider caching weather data (5-15 minutes)

### Permission Errors

Ensure admin users have correct roles:
```sql
UPDATE users SET role = 'superadmin' WHERE phone = '+380999999999';
```

## Support

For issues or questions:
- Check backend logs: `/tmp/dev-backend.log`
- Check cron logs: `/var/log/weather-notifications.log`
- Review API responses for error details
