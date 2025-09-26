# Mobile API Documentation - Free Trial System

## 📋 Backend Developer Implementation Guide

### 🔄 API Changes Summary

The user registration and authentication endpoints now include **free trial functionality**. Here are the updated API responses:

### 1. Registration Endpoint (`POST /api/auth/register`)
**New Behavior**: Automatically creates users with 30-day free trial

**Response includes same fields as before** - no changes needed to mobile app registration flow.

### 2. Login Endpoint (`POST /api/auth/login`)
**New Response Fields Added**:
```json
{
  "message": "Login successful",
  "token": "jwt_token_here",
  "user": {
    "id": "user_id",
    "phone": "+380501234999",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "ship_owner",
    "status": "pending",
    "phone_verified": false,

    // NEW TRIAL FIELDS:
    "subscription_status": "trial",              // "none" | "trial" | "active" | "expired" | "cancelled"
    "trial_expires_at": "2025-10-26T10:02:15.498Z",  // ISO date string
    "trial_days_remaining": 31                   // Number of days left
  }
}
```

### 3. Profile Endpoint (`GET /api/auth/profile`)
**Same new fields as login response above**

### 📱 Mobile App Implementation Requirements

#### 1. Update User Model/Interface
Add these fields to your user data structure:
```typescript
interface User {
  // ... existing fields ...
  subscription_status: 'none' | 'trial' | 'active' | 'expired' | 'cancelled';
  trial_expires_at?: string;        // ISO date string
  trial_days_remaining?: number;    // null if not on trial
}
```

#### 2. Trial Status Checking Logic
```typescript
function hasActiveAccess(user: User): boolean {
  return user.subscription_status === 'trial' || user.subscription_status === 'active';
}

function shouldShowTrialWarning(user: User): boolean {
  return user.subscription_status === 'trial' &&
         user.trial_days_remaining !== null &&
         user.trial_days_remaining <= 7; // Show warning in last 7 days
}

function shouldBlockAccess(user: User): boolean {
  return user.subscription_status === 'none' || user.subscription_status === 'expired';
}
```

#### 3. UI Components Needed

**Trial Badge/Indicator**:
- Show "Free Trial" badge when `subscription_status === 'trial'`
- Display days remaining: `${trial_days_remaining} days left`

**Subscription Prompt**:
- Show when `subscription_status === 'none'` or `'expired'`
- Message: "Your free trial has ended. Choose a subscription plan to continue."

**Trial Warning**:
- Show when trial has ≤7 days remaining
- Message: "Your free trial expires in X days. Subscribe now to continue using the app."

#### 4. App Flow Logic

```typescript
// After login/token refresh
if (user.subscription_status === 'trial') {
  // Allow full access
  // Show trial indicator in UI
  if (user.trial_days_remaining <= 7) {
    // Show gentle subscription reminder
  }
} else if (user.subscription_status === 'active') {
  // Allow full access
  // Show premium indicator
} else {
  // subscription_status is 'none' or 'expired'
  // Show subscription required screen
  // Block access to premium features
}
```

### 🎯 Key Points for Mobile Developer:

1. **No Breaking Changes**: Existing registration/login flow works unchanged
2. **New Users**: Automatically get 30-day trial (no code changes needed)
3. **Check subscription_status**: Use this field to control app access
4. **Trial Days**: Show remaining days to encourage subscription
5. **Graceful Degradation**: Handle missing trial fields for backward compatibility

### 🧪 Test with This User:
- **Phone**: `+380501234999`
- **Password**: `testpassword123`
- **Status**: Currently on trial with ~31 days remaining

### 🔧 Backend Implementation Details

#### Database Schema Changes
The following fields have been added to the `users` table:
- `subscription_status` VARCHAR(20) DEFAULT 'none'
- `current_subscription_id` UUID (nullable)
- `subscription_expires_at` TIMESTAMP (nullable)
- `payment_method_verified` BOOLEAN DEFAULT FALSE
- `notification_preferences` JSON (nullable)
- `trial_started_at` TIMESTAMP (nullable)
- `trial_expires_at` TIMESTAMP (nullable)
- `trial_used` BOOLEAN DEFAULT FALSE

#### Available User Methods
New utility methods available in the User model:
- `UserModel.checkTrialExpiry(userId)` - Checks and updates expired trials
- `UserModel.hasActiveSubscription(userId)` - Returns true if user has active trial or subscription
- `UserModel.getTrialDaysRemaining(userId)` - Returns days remaining in trial or null

#### Trial System Logic
- **Registration**: New users automatically receive 30-day trial
- **Expiry Check**: Trials are automatically expired when accessed after expiry date
- **Status Updates**: Trial status is updated in real-time when accessed
- **Subscription Flow**: Users transition from trial → subscription plans

The backend automatically handles trial expiration - the mobile app just needs to check the `subscription_status` field and respond accordingly.

---

## 📅 Implementation Timeline

**Phase 1 - Backend** ✅ **COMPLETED**
- Database schema updates
- API endpoint modifications
- Trial management logic
- Testing and validation

**Phase 2 - Mobile App** 🔄 **IN PROGRESS**
- Update user models/interfaces
- Implement trial status checking
- Add UI components for trial indication
- Test integration with backend

---

*Last Updated: 2025-09-26*
*Backend API Version: Development*
*Contact: Technical Lead for questions*