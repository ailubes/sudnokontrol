# SUDNO-DPSU Mobile API Documentation

## Overview

This API documentation is designed for mobile app developers building applications for Marina Administrators and Vessel Owners in the SUDNO-DPSU (СудноКонтроль) maritime vessel tracking and notification system.

## Base URLs

- **Production**: `https://api.sudnokontrol.online`
- **Development**: `https://api-dev.sudnokontrol.online`
- **Local Development**: `http://localhost:3030`

All API endpoints are prefixed with `/api`

## Authentication

### JWT Token Authentication

All protected endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

### Login Flow

1. **Register** (if new user) or **Login** with phone/email and password
2. **Verify Phone** with SMS verification code
3. Receive JWT token for subsequent requests
4. Token automatically refreshes on valid requests

---

## 📱 VESSEL OWNER ENDPOINTS

### 🔐 Authentication & Profile Management

#### Register New Account
```http
POST /api/auth/register
Content-Type: application/json

{
  "phone": "+380501234567",
  "email": "owner@example.com",
  "first_name": "Олег",
  "last_name": "Мельник",
  "password": "securePassword123",
  "role": "ship_owner"
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "User registered successfully. Please verify your phone number.",
  "user": {
    "id": "uuid",
    "phone": "+380501234567",
    "email": "owner@example.com",
    "first_name": "Олег",
    "last_name": "Мельник",
    "role": "ship_owner",
    "status": "pending",
    "phone_verified": false
  }
}
```

#### Verify Phone Number
```http
POST /api/auth/verify-phone
Content-Type: application/json

{
  "phone": "+380501234567",
  "verification_code": "123456"
}
```

**Response (200):**
```json
{
  "success": true,
  "message": "Phone number verified successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "phone": "+380501234567",
    "first_name": "Олег",
    "last_name": "Мельник",
    "role": "ship_owner",
    "phone_verified": true,
    "subscription_status": "none"
  }
}
```

#### Login
```http
POST /api/auth/login
Content-Type: application/json

{
  "phone": "+380501234567",
  "password": "securePassword123"
}
```

**Response (200):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid",
    "phone": "+380501234567",
    "first_name": "Олег",
    "last_name": "Мельник",
    "role": "ship_owner",
    "subscription_status": "active",
    "subscription_expires_at": "2024-12-31T23:59:59Z"
  }
}
```

#### Get User Profile
```http
GET /api/auth/profile
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "id": "uuid",
  "phone": "+380501234567",
  "email": "owner@example.com",
  "first_name": "Олег",
  "last_name": "Мельник",
  "role": "ship_owner",
  "status": "verified",
  "phone_verified": true,
  "subscription_status": "active",
  "subscription_expires_at": "2024-12-31T23:59:59Z",
  "notification_preferences": {
    "email": true,
    "sms": true,
    "viber": false,
    "whatsapp": true
  },
  "created_at": "2024-01-15T10:30:00Z",
  "last_login_at": "2024-11-25T14:22:00Z"
}
```

#### Update User Profile
```http
PUT /api/auth/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "first_name": "Олег",
  "last_name": "Мельников",
  "email": "newemail@example.com",
  "notification_preferences": {
    "email": true,
    "sms": true,
    "viber": true,
    "whatsapp": false
  }
}
```

#### Change Password
```http
POST /api/auth/change-password
Authorization: Bearer <token>
Content-Type: application/json

{
  "current_password": "oldPassword123",
  "new_password": "newSecurePassword456"
}
```

---

### 🚢 Vessel Management

#### Get My Vessels
```http
GET /api/vessels/my
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "vessels": [
    {
      "id": "vessel-uuid",
      "registration_number": "UK-1234-AB",
      "name": "Чорноморський",
      "type": "Yacht",
      "length": 12.5,
      "width": 4.2,
      "engine_power": 150,
      "year_built": 2020,
      "status": "active",
      "primary_marina_id": "marina-uuid",
      "marina_name": "Одеський морський порт",
      "technical_inspection_date": "2024-06-15T00:00:00Z",
      "created_at": "2024-01-20T08:00:00Z"
    }
  ]
}
```

#### Create New Vessel
```http
POST /api/vessels
Authorization: Bearer <token>
Content-Type: application/json

{
  "registration_number": "UK-5678-CD",
  "name": "Азовський",
  "type": "Motor Boat",
  "length": 8.5,
  "width": 2.8,
  "draft": 0.8,
  "engine_power": 90,
  "hull_material": "Fiberglass",
  "year_built": 2019,
  "max_passengers": 6,
  "primary_marina_id": "marina-uuid",
  "technical_inspection_date": "2024-08-10T00:00:00Z",
  "notes": "Family boat for weekend trips"
}
```

**Response (201):**
```json
{
  "success": true,
  "vessel": {
    "id": "new-vessel-uuid",
    "registration_number": "UK-5678-CD",
    "name": "Азовський",
    "type": "Motor Boat",
    "status": "active",
    "owner_id": "user-uuid",
    "created_at": "2024-11-25T15:00:00Z"
  }
}
```

#### Update Vessel
```http
PUT /api/vessels/{vessel_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Азовський (Оновлений)",
  "engine_power": 100,
  "notes": "Engine upgraded in 2024"
}
```

#### Get Vessel Details
```http
GET /api/vessels/{vessel_id}
Authorization: Bearer <token>
```

#### Delete Vessel
```http
DELETE /api/vessels/{vessel_id}
Authorization: Bearer <token>
```

---

### 💳 Subscription Management

#### Get Available Plans
```http
GET /api/subscriptions/plans
```

**Response (200):**
```json
{
  "plans": [
    {
      "id": "plan-uuid",
      "name": "Річний безлімітний",
      "type": "annual_unlimited",
      "price": 2400,
      "currency": "UAH",
      "duration_months": 12,
      "description": "Безлімітна кількість виходів протягом року",
      "features": [
        "Безлімітні виходи",
        "GPS трекінг",
        "Миттєві сповіщення",
        "Технічна підтримка"
      ],
      "active": true
    },
    {
      "id": "plan-uuid-2",
      "name": "Місячний безлімітний",
      "type": "monthly_unlimited",
      "price": 250,
      "currency": "UAH",
      "duration_months": 1,
      "features": [
        "Безлімітні виходи",
        "GPS трекінг",
        "Миттєві сповіщення"
      ]
    },
    {
      "id": "plan-uuid-3",
      "name": "Плати за вихід",
      "type": "pay_per_use",
      "price": 50,
      "currency": "UAH",
      "description": "Оплата за кожен вихід окремо",
      "features": [
        "Оплата за використання",
        "GPS трекінг базовий"
      ]
    }
  ]
}
```

#### Get My Subscription
```http
GET /api/subscriptions/my
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "subscription": {
    "id": "sub-uuid",
    "plan_id": "plan-uuid",
    "plan_name": "Річний безлімітний",
    "plan_type": "annual_unlimited",
    "status": "active",
    "starts_at": "2024-01-15T00:00:00Z",
    "expires_at": "2025-01-15T23:59:59Z",
    "auto_renew": true,
    "usage_stats": {
      "total_departures": 25,
      "total_distance_km": 1250.5,
      "avg_trip_duration_hours": 4.2
    }
  }
}
```

#### Subscribe to Plan
```http
POST /api/subscriptions/subscribe
Authorization: Bearer <token>
Content-Type: application/json

{
  "plan_id": "plan-uuid",
  "payment_method": "liqpay",
  "auto_renew": true
}
```

**Response (201):**
```json
{
  "success": true,
  "subscription": {
    "id": "sub-uuid",
    "plan_id": "plan-uuid",
    "status": "pending_payment",
    "payment_url": "https://checkout.liqpay.ua/pay/...",
    "order_id": "order-uuid"
  }
}
```

#### Pay for Single Departure (Pay-per-use)
```http
POST /api/subscriptions/pay-for-departure
Authorization: Bearer <token>
Content-Type: application/json

{
  "vessel_id": "vessel-uuid",
  "departure_details": {
    "destination": "Констанца, Румунія",
    "departure_date": "2024-11-26T08:00:00Z",
    "estimated_return": "2024-11-26T18:00:00Z",
    "purpose": "Риболовля"
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "message": "Payment for departure completed successfully",
  "payment": {
    "amount": 50,
    "currency": "UAH",
    "vessel_id": "vessel-uuid",
    "subscription_id": "sub-uuid"
  }
}
```

#### Get Usage Statistics
```http
GET /api/subscriptions/usage/stats
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "usage_stats": {
    "current_period": {
      "departures_count": 12,
      "total_distance_km": 340.7,
      "total_duration_hours": 48.5,
      "fuel_consumed_liters": 156.2
    },
    "monthly_breakdown": [
      {
        "month": "2024-11",
        "departures": 4,
        "distance_km": 125.3,
        "duration_hours": 16.2
      },
      {
        "month": "2024-10",
        "departures": 8,
        "distance_km": 215.4,
        "duration_hours": 32.3
      }
    ],
    "favorite_destinations": [
      {
        "destination": "Бердянськ",
        "visits": 5,
        "total_distance_km": 87.5
      }
    ]
  }
}
```

#### Get Payment History
```http
GET /api/subscriptions/payments/history
Authorization: Bearer <token>
```

---

### 🧭 Navigation & Trip Management

#### Start New Trip
```http
POST /api/trips
Authorization: Bearer <token>
Content-Type: application/json

{
  "vessel_id": "vessel-uuid",
  "departure_marina_id": "marina-uuid",
  "planned_destination": "Констанца, Румунія",
  "planned_departure_time": "2024-11-26T08:00:00Z",
  "estimated_return_time": "2024-11-26T18:00:00Z",
  "trip_purpose": "Риболовля",
  "passenger_count": 3,
  "route_description": "Одеса - Констанца - Одеса",
  "emergency_contact": {
    "name": "Марина Мельник",
    "phone": "+380501234568"
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "trip": {
    "id": "trip-uuid",
    "vessel_id": "vessel-uuid",
    "status": "planned",
    "departure_marina_id": "marina-uuid",
    "planned_departure_time": "2024-11-26T08:00:00Z",
    "created_at": "2024-11-25T15:30:00Z"
  }
}
```

#### Update Trip (Start/Finish Navigation)
```http
PUT /api/trips/{trip_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "in_progress",
  "actual_departure_time": "2024-11-26T08:15:00Z",
  "current_location": {
    "latitude": 46.4775,
    "longitude": 30.7326,
    "timestamp": "2024-11-26T08:15:00Z"
  }
}
```

#### Finish Trip
```http
PUT /api/trips/{trip_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "completed",
  "actual_return_time": "2024-11-26T17:45:00Z",
  "arrival_marina_id": "marina-uuid",
  "total_distance_km": 145.7,
  "fuel_consumed_liters": 68.5,
  "trip_notes": "Excellent weather, good catch"
}
```

#### Get My Trips
```http
GET /api/trips?vessel_id=vessel-uuid&status=completed&limit=20&offset=0
Authorization: Bearer <token>
```

**Query Parameters:**
- `vessel_id` (optional): Filter by vessel
- `status` (optional): `planned`, `in_progress`, `completed`, `cancelled`
- `date_from` (optional): ISO date string
- `date_to` (optional): ISO date string
- `limit` (optional): Default 50, max 100
- `offset` (optional): Default 0

**Response (200):**
```json
{
  "trips": [
    {
      "id": "trip-uuid",
      "vessel_id": "vessel-uuid",
      "vessel_name": "Чорноморський",
      "status": "completed",
      "planned_departure_time": "2024-11-20T09:00:00Z",
      "actual_departure_time": "2024-11-20T09:12:00Z",
      "actual_return_time": "2024-11-20T16:30:00Z",
      "total_distance_km": 89.3,
      "fuel_consumed_liters": 42.7,
      "departure_marina": "Одеський морський порт",
      "destination": "Бердянськ"
    }
  ],
  "pagination": {
    "total": 156,
    "page": 1,
    "pages": 8,
    "limit": 20
  }
}
```

#### Get Trip Statistics
```http
GET /api/trips/statistics
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "statistics": {
    "total_trips": 45,
    "total_distance_km": 1250.7,
    "total_time_hours": 178.5,
    "average_trip_distance_km": 27.8,
    "average_trip_duration_hours": 4.0,
    "most_visited_destination": "Бердянськ",
    "monthly_stats": [
      {
        "month": "2024-11",
        "trips": 4,
        "distance_km": 156.2,
        "time_hours": 22.5
      }
    ]
  }
}
```

---

### 📍 GPS Tracking

#### Log GPS Position
```http
POST /api/gps/log
Authorization: Bearer <token>
Content-Type: application/json

{
  "vessel_id": "vessel-uuid",
  "latitude": 46.4775,
  "longitude": 30.7326,
  "speed_knots": 12.5,
  "heading": 145,
  "timestamp": "2024-11-26T10:30:00Z",
  "accuracy_meters": 3.2,
  "trip_id": "trip-uuid"
}
```

#### Bulk Log GPS Positions
```http
POST /api/gps/bulk-log
Authorization: Bearer <token>
Content-Type: application/json

{
  "positions": [
    {
      "vessel_id": "vessel-uuid",
      "latitude": 46.4775,
      "longitude": 30.7326,
      "speed_knots": 12.5,
      "heading": 145,
      "timestamp": "2024-11-26T10:30:00Z",
      "trip_id": "trip-uuid"
    },
    {
      "vessel_id": "vessel-uuid",
      "latitude": 46.4785,
      "longitude": 30.7340,
      "speed_knots": 13.2,
      "heading": 147,
      "timestamp": "2024-11-26T10:31:00Z",
      "trip_id": "trip-uuid"
    }
  ]
}
```

#### Get Vessel Track
```http
GET /api/gps/vessel/{vessel_id}/track?from=2024-11-26T00:00:00Z&to=2024-11-26T23:59:59Z
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "vessel_id": "vessel-uuid",
  "track": [
    {
      "latitude": 46.4775,
      "longitude": 30.7326,
      "speed_knots": 12.5,
      "heading": 145,
      "timestamp": "2024-11-26T10:30:00Z"
    }
  ],
  "total_points": 145,
  "total_distance_km": 23.7,
  "duration_hours": 2.5
}
```

#### Get Latest Vessel Position
```http
GET /api/gps/vessel/{vessel_id}/latest
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "vessel_id": "vessel-uuid",
  "position": {
    "latitude": 46.4775,
    "longitude": 30.7326,
    "speed_knots": 0,
    "heading": 0,
    "timestamp": "2024-11-26T15:45:00Z",
    "accuracy_meters": 2.8
  },
  "status": "anchored"
}
```

---

### 📢 Notifications & Movement Reports

#### Create Movement Notification
```http
POST /api/notifications
Authorization: Bearer <token>
Content-Type: application/json

{
  "vessel_id": "vessel-uuid",
  "marina_id": "marina-uuid",
  "type": "planned_departure",
  "planned_time": "2024-11-26T08:00:00Z",
  "route_description": "Одеса - Констанца - Одеса",
  "comments": "Планова риболовля з поверненням у той же день",
  "gps_coordinates": {
    "latitude": 46.4775,
    "longitude": 30.7326
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "notification": {
    "id": "notification-uuid",
    "vessel_id": "vessel-uuid",
    "type": "planned_departure",
    "status": "submitted",
    "planned_time": "2024-11-26T08:00:00Z",
    "created_at": "2024-11-25T15:00:00Z"
  }
}
```

#### Get My Notifications
```http
GET /api/notifications/my?limit=20&offset=0&status=submitted
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "notifications": [
    {
      "id": "notification-uuid",
      "vessel_id": "vessel-uuid",
      "vessel_name": "Чорноморський",
      "marina_name": "Одеський морський порт",
      "type": "planned_departure",
      "status": "approved",
      "planned_time": "2024-11-26T08:00:00Z",
      "route_description": "Одеса - Констанца",
      "approved_at": "2024-11-25T16:30:00Z",
      "created_at": "2024-11-25T15:00:00Z"
    }
  ],
  "pagination": {
    "total": 23,
    "page": 1,
    "pages": 2,
    "limit": 20
  }
}
```

#### Update Movement Notification
```http
PUT /api/notifications/{notification_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "type": "actual_departure",
  "actual_time": "2024-11-26T08:15:00Z",
  "gps_coordinates": {
    "latitude": 46.4785,
    "longitude": 30.7340
  },
  "comments": "Відійшов з невеликою затримкою через погодні умови"
}
```

#### Get Vessel Movement History
```http
GET /api/notifications/vessel/{vessel_id}/history
Authorization: Bearer <token>
```

---

### 🏢 Marina Information

#### Get All Marinas
```http
GET /api/marinas?city=Одеса&limit=50
```

**Response (200):**
```json
{
  "marinas": [
    {
      "id": "marina-uuid",
      "name": "Одеський морський порт",
      "city": "Одеса",
      "country": "Україна",
      "latitude": 46.4775,
      "longitude": 30.7326,
      "phone": "+380482123456",
      "email": "info@odessa-port.ua",
      "facilities": ["fuel", "electricity", "water", "wifi"],
      "services": ["repair", "cleaning", "security"],
      "berth_count": 150,
      "base_rate": 25,
      "currency": "UAH"
    }
  ]
}
```

#### Find Nearby Marinas
```http
GET /api/marinas/nearby?latitude=46.4775&longitude=30.7326&radius_km=50
```

#### Get Marina Details
```http
GET /api/marinas/{marina_id}
```

---

## 🏗️ MARINA ADMIN ENDPOINTS

### 🏢 Marina Management

#### Get My Marinas
```http
GET /api/marinas/admin/my
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "marinas": [
    {
      "id": "marina-uuid",
      "name": "Приватна марина 'Нептун'",
      "city": "Одеса",
      "address": "вул. Морська, 15",
      "phone": "+380501234567",
      "email": "admin@neptune-marina.com",
      "berth_count": 80,
      "occupied_berths": 45,
      "vessel_count": 67,
      "base_rate": 30,
      "currency": "UAH",
      "active": true,
      "facilities": ["fuel", "electricity", "water", "wifi", "restaurant"],
      "services": ["repair", "cleaning", "security", "concierge"]
    }
  ]
}
```

#### Update Marina Information
```http
PUT /api/marinas/{marina_id}
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Приватна марина 'Нептун' (Оновлена)",
  "phone": "+380501234568",
  "facilities": ["fuel", "electricity", "water", "wifi", "restaurant", "laundry"],
  "base_rate": 35
}
```

#### Set Marina Location
```http
POST /api/marinas/{marina_id}/location
Authorization: Bearer <token>
Content-Type: application/json

{
  "latitude": 46.4775,
  "longitude": 30.7326
}
```

### 🚢 Marina Vessel Management

#### Get Vessels at My Marina
```http
GET /api/vessels/marina/{marina_id}
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "vessels": [
    {
      "id": "vessel-uuid",
      "registration_number": "UK-1234-AB",
      "name": "Чорноморський",
      "type": "Yacht",
      "owner_name": "Олег Мельник",
      "owner_phone": "+380501234567",
      "berth_number": "A-15",
      "status": "docked",
      "last_departure": "2024-11-20T09:00:00Z",
      "subscription_status": "active",
      "subscription_expires": "2025-01-15T23:59:59Z"
    }
  ]
}
```

### 📢 Marina Notification Management

#### Get Notifications for My Marina
```http
GET /api/notifications?marina_id=marina-uuid&status=submitted
Authorization: Bearer <token>
```

#### Approve/Review Movement Notification
```http
POST /api/notifications/{notification_id}/validate
Authorization: Bearer <token>
Content-Type: application/json

{
  "action": "approve",
  "admin_comments": "Все документи в порядку, дозвіл на вихід надано",
  "safety_check_completed": true
}
```

#### Send Notification to DPSU
```http
POST /api/notifications/{notification_id}/send-to-dpsu
Authorization: Bearer <token>
```

### 📊 Marina Statistics

#### Get Marina Statistics
```http
GET /api/trips/statistics?marina_id=marina-uuid&date_from=2024-11-01
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "marina_statistics": {
    "total_vessels": 67,
    "active_vessels": 45,
    "departures_this_month": 89,
    "arrivals_this_month": 86,
    "revenue_this_month": 15670,
    "occupancy_rate": 0.75,
    "popular_destinations": [
      {
        "destination": "Бердянськ",
        "departures": 23
      }
    ]
  }
}
```

---

## 🔄 Common Response Patterns

### Success Response
```json
{
  "success": true,
  "data": {
    // Response data
  },
  "message": "Operation completed successfully"
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE",
  "details": {
    // Additional error details
  }
}
```

### Paginated Response
```json
{
  "data": [],
  "pagination": {
    "total": 156,
    "page": 1,
    "pages": 8,
    "limit": 20,
    "offset": 0
  }
}
```

---

## 🔒 Error Codes

### Authentication Errors
- `AUTH_TOKEN_REQUIRED` (401): Missing authorization token
- `AUTH_TOKEN_INVALID` (401): Invalid or expired token
- `AUTH_INSUFFICIENT_PERMISSIONS` (403): User lacks required permissions
- `AUTH_PHONE_NOT_VERIFIED` (403): Phone number not verified

### Validation Errors
- `VALIDATION_ERROR` (400): Request data validation failed
- `INVALID_VESSEL_ID` (400): Vessel ID not found or not owned by user
- `INVALID_MARINA_ID` (400): Marina ID not found
- `SUBSCRIPTION_REQUIRED` (403): Active subscription required for this operation
- `USAGE_LIMIT_EXCEEDED` (403): Subscription usage limit reached

### Business Logic Errors
- `VESSEL_IN_TRANSIT` (409): Vessel is currently on a trip
- `NOTIFICATION_ALREADY_PROCESSED` (409): Notification cannot be modified
- `SUBSCRIPTION_ALREADY_ACTIVE` (409): User already has an active subscription

---

## 📱 Mobile App Implementation Guidelines

### Offline Functionality
- Cache user profile, vessel list, and subscription info locally
- Queue GPS logs when offline and sync when connection is restored
- Store trip data locally during navigation

### Real-time Features
- Implement WebSocket connection for live notifications
- Push notifications for subscription expiry, trip updates
- Real-time GPS tracking during active trips

### Security Recommendations
- Store JWT tokens securely (Keychain/Keystore)
- Implement biometric authentication for app access
- Encrypt sensitive local data
- Validate server certificates

### Performance Optimization
- Implement pagination for all list endpoints
- Use appropriate request timeouts
- Compress GPS tracking data for bulk uploads
- Cache marina and vessel data with TTL

### User Experience
- Provide clear subscription status indicators
- Show trip progress with visual maps
- Implement smooth offline-to-online transitions
- Add push notifications for critical updates

---

## 🌐 WebSocket Events (Real-time)

### Connection
```javascript
const socket = io('wss://api.sudnokontrol.online', {
  auth: {
    token: jwt_token
  }
});
```

### Events for Vessel Owners
- `trip_status_updated`: Trip status changes
- `notification_approved`: Movement notification approved by marina
- `subscription_expiry_warning`: Subscription expiring soon
- `emergency_alert`: Emergency or safety alerts

### Events for Marina Admins
- `new_notification`: New movement notification received
- `vessel_departed`: Vessel left marina
- `vessel_arrived`: Vessel arrived at marina
- `emergency_in_area`: Emergency situation in marina area

---

## 🔧 TECHNICAL SPECIFICATIONS FOR MOBILE DEVELOPERS

### 🔐 Authentication Implementation Details

#### Login Endpoint Specification
**CRITICAL:** The existing client expects exactly this format from `/auth/login`

```http
POST /api/auth/login
Content-Type: application/json

{
  "phone": "+380501234567",
  "password": "userPassword123"
}
```

**Expected Response Format (200):**
```json
{
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJ1dWlkIiwicGhvbmUiOiIrMzgwNTAxMjM0NTY3Iiwicm9sZSI6InNoaXBfb3duZXIiLCJpYXQiOjE3MDA5ODcyMDAsImV4cCI6MTcwMTU5MjAwMH0.signature",
  "user": {
    "id": "uuid",
    "phone": "+380501234567",
    "email": "user@example.com",
    "first_name": "Олег",
    "last_name": "Мельник",
    "role": "ship_owner",
    "status": "verified",
    "phone_verified": true
  }
}
```

#### JWT Token Details
- **Header Name**: `Authorization`
- **Scheme**: `Bearer <token>`
- **Expiry**: **7 days** (hardcoded, not configurable)
- **Algorithm**: HS256
- **Payload Structure**:
  ```json
  {
    "userId": "uuid",
    "phone": "+380501234567",
    "role": "ship_owner",
    "iat": 1700987200,
    "exp": 1701592000
  }
  ```

**Token Usage Example:**
```javascript
const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";

fetch('/api/vessels/my', {
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});
```

#### Phone Verification Endpoint
**IMPORTANT:** After registration, phone verification is required before login works:

```http
POST /api/auth/verify-phone
Content-Type: application/json

{
  "phone": "+380501234567",
  "code": "123456"
}
```

**Response (200):** Returns same structure as login (with token)

### 📋 Required Headers & Parameters

#### Standard Headers for All Requests
```javascript
const headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'User-Agent': 'SUDNO-Mobile/1.0.0 (iOS/Android)'  // Recommended for analytics
};

// For authenticated requests:
headers['Authorization'] = `Bearer ${userToken}`;
```

#### No API Keys Required
- ✅ **No API keys** needed - all authentication is JWT-based
- ✅ **No version headers** required
- ✅ **No locale headers** required (responses are in Ukrainian by default)

#### Optional Headers
- `Accept-Language: uk-UA,en-US` (currently not implemented but recommended for future i18n)
- `X-Client-Version: 1.0.0` (for client version tracking)
- `X-Platform: ios|android` (for platform-specific analytics)

### 🔄 Endpoint Response Changes vs Documentation

#### Additional Fields in Responses

**User Object** (extends documented structure):
```json
{
  "id": "uuid",
  "phone": "+380501234567",
  "email": "user@example.com",
  "first_name": "Олег",
  "last_name": "Мельник",
  "role": "ship_owner",
  "status": "verified",
  "phone_verified": true,

  // ADDITIONAL FIELDS not in basic docs:
  "current_subscription_id": "sub-uuid",
  "subscription_expires_at": "2025-01-15T23:59:59Z",
  "subscription_status": "active|expired|cancelled|none",
  "payment_method_verified": true,
  "notification_preferences": {
    "email": true,
    "sms": true,
    "viber": false,
    "whatsapp": true
  },
  "last_login_at": "2024-11-25T14:22:00Z",
  "created_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-11-25T14:22:00Z"
}
```

**Vessel Object** (additional fields):
```json
{
  "id": "uuid",
  "registration_number": "UK-1234-AB",
  "name": "Чорноморський",
  "type": "Yacht",
  "length": 12.5,
  "width": 4.2,
  "draft": 0.8,
  "engine_power": 150,
  "hull_material": "Fiberglass",
  "year_built": 2020,
  "max_passengers": 6,
  "status": "active",
  "primary_marina_id": "marina-uuid",
  "technical_inspection_date": "2024-06-15T00:00:00Z",
  "notes": "Family boat for weekend trips",

  // ADDITIONAL FIELDS:
  "owner_id": "user-uuid",
  "created_at": "2024-01-20T08:00:00Z",
  "updated_at": "2024-11-25T10:00:00Z"
}
```

**Error Response Structure** (consistent format):
```json
{
  "success": false,
  "error": "Human readable error message",
  "code": "ERROR_CODE_CONSTANT",
  "statusCode": 400,
  "details": {
    "field": "Specific field error details"
  }
}
```

#### TypeScript Interface Updates
**Update your TypeScript interfaces with these additional fields:**

```typescript
interface User {
  id: string;
  phone: string;
  email?: string;
  first_name: string;
  last_name: string;
  role: 'ship_owner' | 'marina_admin' | 'dpsu_admin' | 'superadmin';
  status: 'pending' | 'verified' | 'blocked';
  phone_verified: boolean;
  current_subscription_id?: string;
  subscription_expires_at?: string;
  subscription_status: 'none' | 'active' | 'expired' | 'cancelled';
  payment_method_verified: boolean;
  notification_preferences?: {
    email?: boolean;
    sms?: boolean;
    viber?: boolean;
    whatsapp?: boolean;
  };
  last_login_at?: string;
  created_at: string;
  updated_at: string;
}

interface LoginResponse {
  message: string;
  token: string;
  user: User;
}

interface JWTPayload {
  userId: string;
  phone: string;
  email?: string;
  role: string;
  iat: number;
  exp: number;
}
```

### 🌐 Network Configuration & Constraints

#### CORS Settings
**Development Environment:**
- ✅ Allows: `http://localhost:*` (all localhost ports)
- ✅ Allows: `https://dev.sudnokontrol.online`
- ✅ Credentials: `true` (cookies/auth headers allowed)

**Production Environment:**
- ✅ Allows: `https://sudnokontrol.online`
- ✅ Allows: `https://api.sudnokontrol.online`
- ✅ Allows: `https://dev.sudnokontrol.online`

#### Mobile Development Considerations

**Expo Development:**
```javascript
// For Expo/React Native development
const API_BASE_URL = __DEV__
  ? 'https://api-dev.sudnokontrol.online'  // Use dev API
  : 'https://api.sudnokontrol.online';     // Production API

// DO NOT use localhost - it won't work on physical devices
```

**SSL/TLS Configuration:**
- ✅ **Development**: Uses valid SSL certificate (Let's Encrypt)
- ✅ **No self-signed certificates** - all environments use trusted certificates
- ✅ **No certificate pinning** required
- ✅ **No IP allowlists** - accessible from any IP

#### Network Debugging for Mobile
```javascript
// Test connectivity:
fetch('https://api-dev.sudnokontrol.online/health')
  .then(r => r.json())
  .then(data => console.log('API Health:', data));

// Expected response:
// {
//   "status": "OK",
//   "timestamp": "2024-11-25T15:00:00Z",
//   "version": "1.0.0"
// }
```

#### Request Size Limits
- **JSON Body Limit**: 50MB (configured for large GPS data uploads)
- **URL Encoded**: 50MB
- **File Uploads**: Not currently supported via API (use base64 in JSON if needed)

#### Rate Limiting
- **Currently**: No rate limiting implemented
- **Recommendation**: Implement client-side throttling for GPS logging (max 1 request/second)

#### Timeout Recommendations
```javascript
// Recommended timeouts for mobile apps:
const API_TIMEOUTS = {
  'auth': 10000,      // 10s for login/register
  'vessels': 5000,     // 5s for vessel operations
  'gps': 3000,        // 3s for GPS logging
  'trips': 5000,      // 5s for trip operations
  'default': 8000     // 8s default
};
```

### 🚨 Breaking Changes & Compatibility

#### Phone Number Format
**CRITICAL**: The API automatically formats phone numbers:
- Input: `"0501234567"` → Stored as: `"+380501234567"`
- Input: `"+380501234567"` → Stored as: `"+380501234567"`
- **Always use international format in your mobile app**

#### Date/Time Format
- **All timestamps**: ISO 8601 format (`2024-11-25T15:30:00Z`)
- **Timezone**: UTC (Z suffix)
- **Parsing**: Use `new Date(timestamp)` in JavaScript

#### Field Name Changes
- ✅ No breaking changes from documented field names
- ✅ Additional fields are always optional
- ⚠️ **Future**: May add required fields with defaults

### 🧪 Testing Endpoints

#### Development Testing
```bash
# Test auth flow:
curl -X POST https://api-dev.sudnokontrol.online/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"+380501234567","password":"test123"}'

# Test authenticated endpoint:
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://api-dev.sudnokontrol.online/api/vessels/my
```

#### Health Check for Mobile Apps
Always implement a health check before critical operations:
```javascript
async function checkAPIHealth() {
  try {
    const response = await fetch(`${API_BASE_URL}/health`, {
      timeout: 3000
    });
    const health = await response.json();
    return health.status === 'OK';
  } catch (error) {
    return false;
  }
}
```

---

*This documentation is updated regularly. For the latest version, please refer to the API documentation portal or contact the development team.*

**Critical Issues Contact:** api-support@sudnokontrol.online
**Documentation Version:** 1.1
**Last Updated:** November 25, 2024
**Mobile Development Ready:** ✅