# 📱 SudnoKontrol Mobile API Documentation

> **Mobile Application API Reference**
> Complete API guide for vessel owner and marina owner mobile applications

---

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Authentication](#authentication)
- [Vessel Management](#vessel-management)
- [Trip Management](#trip-management)
- [GPS Tracking](#gps-tracking)
- [Marina Management](#marina-management)
- [Subscriptions & Billing](#subscriptions--billing)
- [Notifications & History](#notifications--history)
- [Mobile-Specific Features](#mobile-specific-features)
- [Error Handling](#error-handling)
- [Code Examples](#code-examples)

---

## 🚀 Quick Start

### Base URL
```
Production: https://api.sudnokontrol.online/api
Development: http://api-dev.sudnokontrol.online/api
```

### Authentication Header
```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### Health Check
```http
GET /health
```

---

## 🔐 Authentication

### 1. Register New User
```http
POST /auth/register
```

**Request:**
```json
{
  "phone": "+380501234567",
  "email": "captain@example.com",
  "first_name": "Іван",
  "last_name": "Коваленко",
  "password": "securePassword123"
}
```

**Response:**
```json
{
  "message": "User registered successfully. Please verify your phone number.",
  "user": {
    "id": "uuid",
    "phone": "+380501234567",
    "email": "captain@example.com",
    "first_name": "Іван",
    "last_name": "Коваленко",
    "role": "ship_owner",
    "status": "pending",
    "phone_verified": false
  }
}
```

### 2. Login
```http
POST /auth/login
```

**Request:**
```json
{
  "phone": "+380501234567",
  "password": "securePassword123"
}
```

**Response:**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "phone": "+380501234567",
    "first_name": "Іван",
    "last_name": "Коваленко",
    "role": "ship_owner",
    "status": "verified"
  }
}
```

### 3. Verify Phone Number
```http
POST /auth/verify-phone
```

**Request:**
```json
{
  "phone": "+380501234567",
  "code": "123456"
}
```

### 4. Get User Profile
```http
GET /auth/profile
Authorization: Bearer <token>
```

### 5. Update Profile
```http
PUT /auth/profile
Authorization: Bearer <token>
```

**Request:**
```json
{
  "email": "newemail@example.com",
  "first_name": "Петро",
  "last_name": "Новий",
  "notification_preferences": {
    "push_notifications": true,
    "email_notifications": true,
    "sms_notifications": false
  }
}
```

---

## 🚢 Vessel Management

### 1. Add New Vessel
```http
POST /vessels
Authorization: Bearer <token>
```

**Request:**
```json
{
  "registration_number": "UA-0001-OD",
  "name": "Дельфін",
  "type": "Моторний катер",
  "length": 8.5,
  "width": 2.8,
  "engine_power": 250,
  "max_passengers": 8,
  "primary_marina_id": "uuid",
  "insurance_number": "INS-12345",
  "insurance_expiry": "2024-12-31"
}
```

**Response:**
```json
{
  "message": "Vessel created successfully",
  "vessel": {
    "id": "uuid",
    "registration_number": "UA-0001-OD",
    "name": "Дельфін",
    "type": "Моторний катер",
    "length": 8.5,
    "width": 2.8,
    "engine_power": 250,
    "status": "active",
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

### 2. Get My Vessels
```http
GET /vessels/my?page=1&limit=20&status=active
Authorization: Bearer <token>
```

**Response:**
```json
{
  "vessels": [
    {
      "id": "uuid",
      "registration_number": "UA-0001-OD",
      "name": "Дельфін",
      "type": "Моторний катер",
      "length": 8.5,
      "status": "active",
      "last_position": {
        "latitude": 46.4775,
        "longitude": 30.7326,
        "recorded_at": "2024-01-15T14:30:00Z"
      },
      "current_marina": {
        "id": "uuid",
        "name": "Центральна Марина Одеси"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 3,
    "totalPages": 1
  }
}
```

### 3. Get Vessel Details
```http
GET /vessels/:id
Authorization: Bearer <token>
```

### 4. Update Vessel
```http
PUT /vessels/:id
Authorization: Bearer <token>
```

### 5. Delete Vessel
```http
DELETE /vessels/:id
Authorization: Bearer <token>
```

---

## 🗺️ Trip Management

### 1. Get My Trips
```http
GET /trips/my?limit=20&offset=0&status=active
Authorization: Bearer <token>
```

**Description**: Get all trips for the authenticated user.

**Query Parameters** (all optional):
- `limit` - Number of trips to return (default: 20)
- `offset` - Pagination offset (default: 0)
- `status` - Filter by status: `active`, `completed`, `cancelled`

**Response:**
```json
{
  "success": true,
  "trips": [
    {
      "id": "165e6976-dfdd-4411-bc7f-416af44e573b",
      "vessel_id": "a25ac569-5ea7-4326-8cd1-a70a0504a50b",
      "vessel_name": "Дельфін",
      "vessel_registration": "UA-0001-OD",
      "owner_name": "Іван Коваленко",
      "owner_phone": "+380501234567",
      "departure_marina_id": "d35583ce-8412-4398-81ff-53adeeb3e346",
      "departure_marina_name": "Одеський морський порт",
      "arrival_marina_id": "f45583ce-8412-4398-81ff-53adeeb3e347",
      "arrival_marina_name": "Іллічівський порт",
      "departure_time": "2024-01-15T10:00:00.000Z",
      "arrival_time": "2024-01-15T18:00:00.000Z",
      "status": "in_progress",
      "distance_km": 45.5,
      "duration_hours": 4.2,
      "avg_speed_kmh": 9.2,
      "max_speed_kmh": 15.7,
      "captain_name": "Іван Коваленко",
      "passengers_count": 3,
      "purpose": "Recreational",
      "notes": "Coastal route along Black Sea",
      "created_at": "2024-01-15T09:30:00.000Z",
      "updated_at": "2024-01-15T10:00:00.000Z"
    }
  ],
  "pagination": {
    "total": 3,
    "limit": 20,
    "offset": 0,
    "pages": 1
  }
}
```

### 2. Get Trip Details
```http
GET /trips/:id
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "trip": {
    "id": "165e6976-dfdd-4411-bc7f-416af44e573b",
    "vessel_id": "a25ac569-5ea7-4326-8cd1-a70a0504a50b",
    "vessel_name": "Дельфін",
    "vessel_registration": "UA-0001-OD",
    "owner_name": "Іван Коваленко",
    "owner_phone": "+380501234567",
    "departure_marina_id": "d35583ce-8412-4398-81ff-53adeeb3e346",
    "departure_marina_name": "Одеський морський порт",
    "arrival_marina_id": "f45583ce-8412-4398-81ff-53adeeb3e347",
    "arrival_marina_name": "Іллічівський порт",
    "departure_time": "2024-01-15T10:00:00.000Z",
    "arrival_time": "2024-01-15T18:00:00.000Z",
    "status": "in_progress",
    "distance_km": 45.5,
    "duration_hours": 4.2,
    "captain_name": "Іван Коваленко",
    "passengers_count": 3,
    "purpose": "Recreational",
    "notes": "Coastal route along Black Sea",
    "created_at": "2024-01-15T09:30:00.000Z",
    "updated_at": "2024-01-15T10:00:00.000Z"
  }
}
```

### 3. Create New Trip
```http
POST /trips
Authorization: Bearer <token>
```

**Request:**
```json
{
  "vessel_id": "a25ac569-5ea7-4326-8cd1-a70a0504a50b",
  "departure_marina_id": "d35583ce-8412-4398-81ff-53adeeb3e346",
  "arrival_marina_id": "f45583ce-8412-4398-81ff-53adeeb3e347",
  "departure_time": "2024-01-15T10:00:00.000Z",
  "planned_arrival_time": "2024-01-15T18:00:00.000Z",
  "purpose": "Recreational",
  "crew_count": 2,
  "passenger_count": 4,
  "route_description": "Coastal fishing trip"
}
```

**Required Fields:**
- `vessel_id` (UUID)
- `departure_marina_id` (UUID)
- `departure_time` (ISO 8601 date string)
- `purpose` (string)

**Optional Fields:**
- `arrival_marina_id` (UUID)
- `planned_arrival_time` (ISO 8601 date string)
- `crew_count` (integer, default: 1)
- `passenger_count` (integer, default: 0)
- `route_description` (string)

**Response:**
```json
{
  "success": true,
  "trip": {
    "id": "new-trip-uuid",
    "vessel_id": "a25ac569-5ea7-4326-8cd1-a70a0504a50b",
    "owner_id": "owner-uuid",
    "departure_marina_id": "d35583ce-8412-4398-81ff-53adeeb3e346",
    "arrival_marina_id": "f45583ce-8412-4398-81ff-53adeeb3e347",
    "departure_time": "2024-01-15T10:00:00.000Z",
    "planned_arrival_time": "2024-01-15T18:00:00.000Z",
    "status": "active",
    "purpose": "Recreational",
    "crew_count": 2,
    "passenger_count": 4,
    "route_description": "Coastal fishing trip",
    "created_at": "2024-01-15T09:30:00.000Z",
    "updated_at": "2024-01-15T09:30:00.000Z"
  }
}
```

### 4. Update Trip
```http
PUT /trips/:id
Authorization: Bearer <token>
```

**Request (all fields optional):**
```json
{
  "arrival_marina_id": "new-marina-uuid",
  "planned_arrival_time": "2024-01-15T20:00:00.000Z",
  "crew_count": 3,
  "passenger_count": 5,
  "route_description": "Updated route description"
}
```

**Response:**
```json
{
  "success": true,
  "trip": {
    "id": "165e6976-dfdd-4411-bc7f-416af44e573b",
    "vessel_id": "a25ac569-5ea7-4326-8cd1-a70a0504a50b",
    "owner_id": "owner-uuid",
    "departure_marina_id": "d35583ce-8412-4398-81ff-53adeeb3e346",
    "arrival_marina_id": "new-marina-uuid",
    "departure_time": "2024-01-15T10:00:00.000Z",
    "planned_arrival_time": "2024-01-15T20:00:00.000Z",
    "status": "active",
    "crew_count": 3,
    "passenger_count": 5,
    "route_description": "Updated route description",
    "updated_at": "2024-01-15T12:00:00.000Z"
  }
}
```

### 5. Complete Trip
```http
POST /trips/:id/complete
Authorization: Bearer <token>
```

**Request (all fields optional):**
```json
{
  "arrival_marina_id": "f45583ce-8412-4398-81ff-53adeeb3e347",
  "actual_arrival_time": "2024-01-15T18:30:00.000Z"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Trip completed successfully",
  "trip": {
    "id": "165e6976-dfdd-4411-bc7f-416af44e573b",
    "status": "completed",
    "actual_arrival_time": "2024-01-15T18:30:00.000Z",
    "duration_hours": "8.50",
    "updated_at": "2024-01-15T18:30:00.000Z"
  }
}
```

**Note**: Duration is automatically calculated from `departure_time` to `actual_arrival_time`.

### 6. Delete Trip
```http
DELETE /trips/:id
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "Trip deleted successfully"
}
```

### 7. Get Trip GPS Track
```http
GET /trips/:id/track?format=json&simplified=false
Authorization: Bearer <token>
```

**Query Parameters** (all optional):
- `format` - Response format: `json` (default)
- `simplified` - Reduce track points for better performance: `true` | `false` (default)

**Response:**
```json
{
  "success": true,
  "trip_id": "a25ac569-5ea7-4326-8cd1-a70a0504a50b",
  "track": [
    {
      "latitude": 46.4775,
      "longitude": 30.7326,
      "speed": 8.5,
      "heading": 180,
      "accuracy": 5.0,
      "altitude": 2.0,
      "recorded_at": "2024-01-15T10:00:00.000Z",
      "timestamp": 1705316400000
    },
    {
      "latitude": 46.4780,
      "longitude": 30.7330,
      "speed": 9.2,
      "heading": 185,
      "accuracy": 4.5,
      "altitude": 2.5,
      "recorded_at": "2024-01-15T10:01:00.000Z",
      "timestamp": 1705316460000
    }
  ],
  "statistics": {
    "total_points": 204,
    "simplified_points": 100,
    "distance_km": 45.5,
    "max_speed": 15.7,
    "avg_speed": 9.2,
    "duration_hours": 8.5,
    "start_time": "2024-01-15T10:00:00.000Z",
    "end_time": "2024-01-15T18:30:00.000Z"
  }
}
```

**Note**:
- Trip statistics (distance, avg_speed, max_speed) are automatically calculated from GPS data and saved to the trip record
- Use `simplified=true` for trips with >100 GPS points to reduce data transfer

### 8. Get Trip Statistics
```http
GET /trips/statistics
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "statistics": {
    "total_trips": 15,
    "active_trips": 2,
    "completed_trips": 12,
    "cancelled_trips": 1,
    "total_distance": 456.7,
    "avg_distance": 30.45,
    "total_duration": 127.5,
    "recent_activity": [
      {
        "date": "2024-01-15",
        "count": 3
      },
      {
        "date": "2024-01-14",
        "count": 1
      }
    ]
  }
}
```

### 8. Start New Trip (Legacy - Departure Notification)
```http
POST /notifications
Authorization: Bearer <token>
```

**Request:**
```json
{
  "vessel_id": "uuid",
  "marina_id": "uuid",
  "type": "actual_departure",
  "actual_time": "2024-01-15T10:00:00Z",
  "route_description": "Вихід в море для риболовлі біля острова Зміїний",
  "planned_return_time": "2024-01-15T18:00:00Z",
  "passenger_count": 4,
  "emergency_contact": {
    "name": "Марія Коваленко",
    "phone": "+380671234567"
  },
  "gps_coordinates": {
    "latitude": 46.4775,
    "longitude": 30.7326
  }
}
```

**Response:**
```json
{
  "message": "Trip started successfully",
  "notification": {
    "id": "uuid",
    "vessel_id": "uuid",
    "type": "actual_departure",
    "status": "submitted",
    "trip_id": "TRIP-2024-001",
    "created_at": "2024-01-15T10:00:00Z"
  }
}
```

### 9. End Trip (Legacy - Arrival Notification)
```http
POST /notifications
Authorization: Bearer <token>
```

**Request:**
```json
{
  "vessel_id": "uuid",
  "marina_id": "uuid",
  "type": "actual_arrival",
  "actual_time": "2024-01-15T17:30:00Z",
  "route_description": "Повернення з риболовлі",
  "comments": "Успішна риболовля, всі на борту здорові",
  "gps_coordinates": {
    "latitude": 46.4825,
    "longitude": 30.7233
  }
}
```

---

## 📍 GPS Tracking

### 1. Log GPS Position
```http
POST /gps/log
Authorization: Bearer <token>
```

**Request:**
```json
{
  "vessel_id": "uuid",
  "location": {
    "latitude": 46.4775,
    "longitude": 30.7326
  },
  "speed": 8.5,
  "heading": 180,
  "accuracy": 5,
  "altitude": 2,
  "recorded_at": "2024-01-15T10:15:00Z",
  "source": "mobile_app"
}
```

### 2. Bulk Log GPS Positions (for offline sync)
```http
POST /gps/bulk-log
Authorization: Bearer <token>
```

**Request:**
```json
{
  "positions": [
    {
      "vessel_id": "uuid",
      "location": { "latitude": 46.4775, "longitude": 30.7326 },
      "speed": 8.5,
      "heading": 180,
      "recorded_at": "2024-01-15T10:00:00Z"
    },
    {
      "vessel_id": "uuid",
      "location": { "latitude": 46.4780, "longitude": 30.7330 },
      "speed": 9.2,
      "heading": 185,
      "recorded_at": "2024-01-15T10:01:00Z"
    }
  ]
}
```

### 3. Get Vessel Track
```http
GET /gps/vessel/:vesselId/track?from=2024-01-15T00:00:00Z&to=2024-01-15T23:59:59Z
Authorization: Bearer <token>
```

**Response:**
```json
{
  "vessel_id": "uuid",
  "track": [
    {
      "location": { "latitude": 46.4775, "longitude": 30.7326 },
      "speed": 8.5,
      "heading": 180,
      "recorded_at": "2024-01-15T10:00:00Z"
    }
  ],
  "statistics": {
    "total_points": 287,
    "distance_traveled": 24.5,
    "max_speed": 12.3,
    "average_speed": 8.7,
    "duration": "7:30:00",
    "start_time": "2024-01-15T10:00:00Z",
    "end_time": "2024-01-15T17:30:00Z"
  }
}
```

### 4. Get Latest Position
```http
GET /gps/vessel/:vesselId/latest
Authorization: Bearer <token>
```

**Response:**
```json
{
  "vessel_id": "uuid",
  "location": {
    "latitude": 46.4825,
    "longitude": 30.7233
  },
  "speed": 0,
  "heading": 0,
  "recorded_at": "2024-01-15T17:30:00Z",
  "status": "docked",
  "marina": {
    "id": "uuid",
    "name": "Центральна Марина Одеси"
  }
}
```

### 5. Get Vessel Statistics
```http
GET /gps/vessel/:vesselId/stats?period=30d
Authorization: Bearer <token>
```

**Response:**
```json
{
  "period": "30d",
  "total_trips": 12,
  "total_distance": 387.2,
  "total_time": "96:15:00",
  "max_speed": 15.7,
  "average_speed": 9.2,
  "most_visited_areas": [
    {
      "name": "Одеська затока",
      "visits": 8,
      "time_spent": "45:30:00"
    }
  ],
  "activity_by_day": [
    { "date": "2024-01-15", "trips": 2, "distance": 24.5 }
  ]
}
```

---

## ⚓ Marina Management

### 1. Find Nearby Marinas
```http
GET /marinas/nearby?lat=46.4825&lng=30.7233&radius=50&limit=20
```

**Response:**
```json
{
  "marinas": [
    {
      "id": "uuid",
      "name": "Центральна Марина Одеси",
      "address": "м. Одеса, Приморський район",
      "city": "Одеса",
      "distance": 2.3,
      "coordinates": {
        "latitude": 46.4825,
        "longitude": 30.7233
      },
      "facilities": ["fuel", "water", "electricity", "wifi"],
      "contact": {
        "phone": "+380487654321",
        "email": "info@marinaodessa.com"
      },
      "capacity": {
        "total_berths": 150,
        "available_berths": 23
      },
      "rates": {
        "daily": 200,
        "monthly": 5000,
        "currency": "UAH"
      }
    }
  ]
}
```

### 2. Get Marina Details
```http
GET /marinas/:id
```

### 3. Get Marina Vessel Count
```http
GET /marinas/:id/vessel-count
```

### 4. Request Marina Assignment
```http
POST /vessel-marina/request
Authorization: Bearer <token>
```

**Request:**
```json
{
  "vessel_id": "uuid",
  "marina_id": "uuid",
  "assignment_type": "permanent",
  "start_date": "2024-02-01",
  "end_date": "2024-12-31",
  "berth_preference": "covered",
  "special_requirements": ["electricity", "water", "security"],
  "notes": "Катер потребує зарядки електромоторів щоденно"
}
```

### 5. Get My Marina Assignments
```http
GET /vessel-marina/my?status=active
Authorization: Bearer <token>
```

---

## 💳 Subscriptions & Billing

### 1. Get Available Plans
```http
GET /subscriptions/plans
```

**Response:**
```json
{
  "plans": [
    {
      "id": "uuid",
      "name": "Базовий",
      "description": "Ідеально для власників одного-двох суден",
      "type": "monthly",
      "price": 299.00,
      "currency": "UAH",
      "features": [
        "До 2 суден",
        "GPS трекінг",
        "Базові повідомлення",
        "Мобільний додаток",
        "Email підтримка"
      ],
      "limits": {
        "max_vessels": 2,
        "max_notifications_per_month": 50,
        "gps_history_days": 30,
        "api_calls_per_hour": 100
      },
      "popular": false
    },
    {
      "id": "uuid",
      "name": "Професійний",
      "description": "Для активних власників флоту",
      "type": "monthly",
      "price": 599.00,
      "currency": "UAH",
      "features": [
        "До 10 суден",
        "Розширений GPS трекінг",
        "Всі типи повідомлень",
        "Аналітика маршрутів",
        "Пріоритетна підтримка",
        "Експорт даних"
      ],
      "limits": {
        "max_vessels": 10,
        "max_notifications_per_month": 200,
        "gps_history_days": 90,
        "api_calls_per_hour": 500
      },
      "popular": true
    }
  ]
}
```

### 2. Get My Subscription
```http
GET /subscriptions/my
Authorization: Bearer <token>
```

**Response:**
```json
{
  "subscription": {
    "id": "uuid",
    "plan": {
      "name": "Професійний",
      "price": 599.00,
      "currency": "UAH"
    },
    "status": "active",
    "current_period_start": "2024-01-01T00:00:00Z",
    "current_period_end": "2024-02-01T00:00:00Z",
    "auto_renew": true,
    "trial_end": null
  },
  "usage": {
    "vessels_used": 3,
    "vessels_limit": 10,
    "notifications_this_month": 12,
    "notifications_limit": 200,
    "usage_percentage": 6
  },
  "next_billing": {
    "date": "2024-02-01T00:00:00Z",
    "amount": 599.00,
    "currency": "UAH"
  }
}
```

### 3. Subscribe to Plan
```http
POST /subscriptions/subscribe
Authorization: Bearer <token>
```

**Request:**
```json
{
  "plan_id": "uuid",
  "payment_method": "card",
  "auto_renew": true
}
```

### 4. Get Usage Statistics
```http
GET /subscriptions/usage/stats?period=current_month
Authorization: Bearer <token>
```

### 5. Check Usage Limit
```http
GET /subscriptions/usage/check-limit
Authorization: Bearer <token>
```

### 6. Get Payment History
```http
GET /subscriptions/payments/history?page=1&limit=10
Authorization: Bearer <token>
```

---

## 📨 Notifications & History

### 1. Get My Notifications
```http
GET /notifications/my?page=1&limit=20&type=departure&status=submitted
Authorization: Bearer <token>
```

### 2. Get Notification Details
```http
GET /notifications/:id
Authorization: Bearer <token>
```

### 3. Update Notification
```http
PUT /notifications/:id
Authorization: Bearer <token>
```

### 4. Delete Notification
```http
DELETE /notifications/:id
Authorization: Bearer <token>
```

### 5. Validate Movement
```http
POST /notifications/:id/validate
Authorization: Bearer <token>
```

**Request:**
```json
{
  "validation_type": "automatic",
  "gps_correlation": true,
  "time_correlation": true
}
```

---

## 📱 Mobile-Specific Features

### 1. Offline Mode Support

#### Sync Pending GPS Logs
```http
POST /gps/bulk-log
Authorization: Bearer <token>
```

#### Get Sync Status
```http
GET /sync/status
Authorization: Bearer <token>
```

### 2. Push Notifications Setup

#### Register Device for Push Notifications
```http
POST /push/register
Authorization: Bearer <token>
```

**Request:**
```json
{
  "device_token": "fcm_device_token_here",
  "platform": "android", // or "ios"
  "app_version": "1.2.3",
  "device_info": {
    "model": "Samsung Galaxy S21",
    "os_version": "Android 12"
  }
}
```

#### Update Notification Preferences
```http
PUT /push/preferences
Authorization: Bearer <token>
```

**Request:**
```json
{
  "trip_reminders": true,
  "weather_alerts": true,
  "marina_notifications": false,
  "system_updates": true
}
```

### 3. App Configuration

#### Get App Config
```http
GET /config/mobile
Authorization: Bearer <token>
```

**Response:**
```json
{
  "config": {
    "gps_tracking_interval": 30, // seconds
    "offline_sync_interval": 300, // seconds
    "max_offline_storage_hours": 24,
    "features": {
      "voice_notes": true,
      "photo_upload": true,
      "weather_integration": true,
      "emergency_contacts": true
    },
    "map_settings": {
      "default_zoom": 12,
      "max_zoom": 18,
      "tile_server": "mapbox"
    }
  }
}
```

---

## ❌ Error Handling

### Standard Error Response
```json
{
  "error": "Помилка валідації даних",
  "code": "VALIDATION_ERROR",
  "details": {
    "vessel_id": "Обов'язкове поле",
    "location": "Неправильні GPS координати"
  },
  "timestamp": "2024-01-15T10:00:00Z",
  "request_id": "req_123456789"
}
```

### Common Error Codes

#### Authentication Errors
- `INVALID_CREDENTIALS` - Неправильний телефон або пароль
- `ACCOUNT_BLOCKED` - Акаунт заблоковано
- `PHONE_NOT_VERIFIED` - Телефон не підтверджено
- `TOKEN_EXPIRED` - Токен прострочено

#### Vessel Management Errors
- `VESSEL_NOT_FOUND` - Судно не знайдено
- `VESSEL_NOT_OWNED` - Судно не належить користувачу
- `DUPLICATE_REGISTRATION` - Реєстраційний номер вже існує

#### Trip Management Errors
- `ACTIVE_TRIP_EXISTS` - Вже є активна поїздка
- `NO_ACTIVE_TRIP` - Немає активної поїздки
- `INVALID_MARINA` - Неправильна марина

#### Subscription Errors
- `USAGE_LIMIT_EXCEEDED` - Перевищено ліміт використання
- `SUBSCRIPTION_EXPIRED` - Підписка прострочена
- `PAYMENT_FAILED` - Помилка оплати

---

## 💻 Code Examples

### React Native / JavaScript

#### Authentication
```javascript
class SudnoAPI {
  constructor() {
    this.baseURL = 'https://api.sudnokontrol.online/api';
    this.token = null;
  }

  async login(phone, password) {
    const response = await fetch(`${this.baseURL}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ phone, password })
    });

    const data = await response.json();
    if (response.ok) {
      this.token = data.token;
      await AsyncStorage.setItem('token', data.token);
      return data.user;
    }
    throw new Error(data.error);
  }

  async startTrip(vesselId, marinaId, routeDescription) {
    const position = await getCurrentPosition();

    const response = await fetch(`${this.baseURL}/notifications`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.token}`
      },
      body: JSON.stringify({
        vessel_id: vesselId,
        marina_id: marinaId,
        type: 'actual_departure',
        actual_time: new Date().toISOString(),
        route_description: routeDescription,
        gps_coordinates: {
          latitude: position.coords.latitude,
          longitude: position.coords.longitude
        }
      })
    });

    return await response.json();
  }

  async logGPSPosition(vesselId, position) {
    const response = await fetch(`${this.baseURL}/gps/log`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.token}`
      },
      body: JSON.stringify({
        vessel_id: vesselId,
        location: {
          latitude: position.coords.latitude,
          longitude: position.coords.longitude
        },
        speed: position.coords.speed || 0,
        heading: position.coords.heading || 0,
        accuracy: position.coords.accuracy,
        recorded_at: new Date().toISOString(),
        source: 'mobile_app'
      })
    });

    return await response.json();
  }
}
```

#### GPS Tracking Service
```javascript
class GPSTracker {
  constructor(api, vesselId) {
    this.api = api;
    this.vesselId = vesselId;
    this.interval = null;
    this.offlineQueue = [];
  }

  start() {
    this.interval = setInterval(async () => {
      try {
        const position = await getCurrentPosition({
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 30000
        });

        if (NetInfo.isConnected) {
          // Online: send immediately
          await this.api.logGPSPosition(this.vesselId, position);

          // Send any queued offline data
          if (this.offlineQueue.length > 0) {
            await this.syncOfflineData();
          }
        } else {
          // Offline: queue for later
          this.offlineQueue.push({
            vessel_id: this.vesselId,
            location: {
              latitude: position.coords.latitude,
              longitude: position.coords.longitude
            },
            speed: position.coords.speed || 0,
            recorded_at: new Date().toISOString()
          });
        }
      } catch (error) {
        console.error('GPS tracking error:', error);
      }
    }, 30000); // Track every 30 seconds
  }

  async syncOfflineData() {
    if (this.offlineQueue.length === 0) return;

    try {
      await this.api.bulkLogGPS(this.offlineQueue);
      this.offlineQueue = [];
    } catch (error) {
      console.error('Failed to sync offline GPS data:', error);
    }
  }

  stop() {
    if (this.interval) {
      clearInterval(this.interval);
      this.interval = null;
    }
  }
}
```

### Swift / iOS

#### API Client
```swift
class SudnoAPIClient {
    let baseURL = "https://api.sudnokontrol.online/api"
    var token: String?

    func login(phone: String, password: String) async throws -> User {
        let url = URL(string: "\(baseURL)/auth/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = ["phone": phone, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
            self.token = loginResponse.token
            return loginResponse.user
        } else {
            let error = try JSONDecoder().decode(APIError.self, from: data)
            throw APIException.serverError(error.error)
        }
    }

    func startTrip(vesselId: String, marinaId: String, description: String) async throws -> TripResponse {
        let url = URL(string: "\(baseURL)/notifications")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")

        let location = await getCurrentLocation()
        let body: [String: Any] = [
            "vessel_id": vesselId,
            "marina_id": marinaId,
            "type": "actual_departure",
            "actual_time": ISO8601DateFormatter().string(from: Date()),
            "route_description": description,
            "gps_coordinates": [
                "latitude": location.coordinate.latitude,
                "longitude": location.coordinate.longitude
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TripResponse.self, from: data)
    }
}
```

---

## 📝 Best Practices

### 1. Authentication Management
- Store JWT tokens securely (Keychain on iOS, Encrypted SharedPreferences on Android)
- Implement automatic token refresh
- Handle token expiration gracefully
- Clear tokens on logout

### 2. GPS Tracking
- Use appropriate accuracy settings to balance battery life
- Implement offline queuing for poor connectivity
- Batch GPS updates when possible
- Respect user privacy settings

### 3. Error Handling
- Always check for network connectivity
- Implement retry mechanisms for failed requests
- Show user-friendly error messages in Ukrainian
- Log errors for debugging

### 4. Performance
- Cache frequently accessed data (marinas, vessel list)
- Use pagination for large data sets
- Implement pull-to-refresh patterns
- Optimize image loading and caching

### 5. User Experience
- Show loading states during API calls
- Implement offline-first functionality
- Provide clear feedback for all actions
- Support Ukrainian language throughout

---

## 🔧 Rate Limits

- **Authentication**: 5 requests/minute per IP
- **GPS Logging**: 120 requests/minute per user
- **Standard API**: 60 requests/minute per user
- **Bulk Operations**: 10 requests/minute per user

---

## 🆘 Support

### Technical Support
- **Email**: mobile-support@sudnokontrol.online
- **Telegram**: @sudno_support
- **Hours**: Пн-Пт 9:00-18:00 (UTC+2)

### Emergency Contact
- **24/7 Hotline**: +380 800 123 456
- **DPSU Emergency**: 112

---

**Last Updated**: January 22, 2025
**API Version**: 2.0.0
**Mobile API Version**: 1.0.0

---

*🇺🇦 Створено для мобільних додатків системи контролю суден ДПСУ*
