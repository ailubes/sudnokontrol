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
---

# 💳 LiqPay Subscription & Payment Integration

**Status:** ✅ Fully Implemented and Operational (Sandbox Mode)  
**Last Updated:** October 1, 2025

## 📋 Overview

The subscription system is now fully integrated with LiqPay payment gateway. Users can subscribe to paid plans using credit/debit cards through LiqPay's secure payment interface.

---

## 🔐 LiqPay Credentials

**Environment:** Development (Sandbox)
```
Public Key: sandbox_i47115455584
Private Key: sandbox_OgFbEGuhwjJi4taO8LKfCODL2jTRis0ex7PTVRMp
Sandbox Mode: true
```

**Note:** Use these credentials in your mobile app for testing. They work with LiqPay's sandbox environment.

---

## 🚀 Subscription Flow

### Complete Payment Journey

```
1. User browses subscription plans
   ↓
2. User selects a plan and taps "Subscribe"
   ↓
3. App calls POST /api/subscriptions/subscribe
   ↓
4. Backend creates pending subscription + transaction
   ↓
5. Backend returns LiqPay payment form/URL
   ↓
6. App opens payment in WebView or browser
   ↓
7. User completes payment in LiqPay
   ↓
8. LiqPay calls webhook → Backend activates subscription
   ↓
9. User returns to app → Refresh profile to see active subscription
```

---

## 📡 API Endpoints

### 1. Get Available Subscription Plans

```http
GET https://api-dev.sudnokontrol.online/api/subscriptions/plans
Authorization: Bearer <jwt_token>
```

**Response:**
```json
{
  "plans": [
    {
      "id": "uuid-plan-1",
      "name": "Власник Персональний",
      "description": "Для приватних власників суден",
      "type": "monthly_unlimited",
      "price": 300,
      "currency": "UAH",
      "duration_months": 1,
      "features": [
        "До 3 власних суден",
        "GPS трекінг",
        "Повідомлення про відправлення/прибуття",
        "Основні звіти",
        "Email підтримка"
      ],
      "active": true,
      "role_restrictions": ["ship_owner"],
      "created_at": "2025-10-01T00:00:00Z"
    },
    {
      "id": "uuid-plan-2",
      "name": "Власник Бізнес",
      "description": "Для комерційних власників флоту",
      "type": "monthly_unlimited",
      "price": 1200,
      "currency": "UAH",
      "duration_months": 1,
      "features": [
        "До 20 суден",
        "Розширена аналітика",
        "Управління екіпажем",
        "API доступ",
        "Пріоритетна підтримка"
      ],
      "active": true,
      "role_restrictions": ["ship_owner"]
    }
  ]
}
```

**Plan Types:**
- `monthly_unlimited` - Monthly subscription with unlimited usage
- `annual_unlimited` - Annual subscription with unlimited usage
- `pay_per_use` - Pay per verification (credits-based)

---

### 2. Subscribe to a Plan

```http
POST https://api-dev.sudnokontrol.online/api/subscriptions/subscribe
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "plan_id": "uuid-of-selected-plan",
  "auto_renew": false,
  "payment_method": "liqpay"
}
```

**Response:**
```json
{
  "message": "Subscription created successfully",
  "subscription": {
    "id": "uuid-subscription-id",
    "user_id": "user-uuid",
    "plan_id": "plan-uuid",
    "status": "pending",
    "starts_at": "2025-10-01T19:00:00Z",
    "expires_at": "2025-11-01T19:00:00Z",
    "auto_renew": false,
    "usage_count": 0,
    "credits_remaining": 0,
    "created_at": "2025-10-01T19:00:00Z"
  },
  "transaction": {
    "id": "uuid-transaction-id",
    "user_id": "user-uuid",
    "subscription_id": "uuid-subscription-id",
    "amount": 300,
    "currency": "UAH",
    "status": "pending",
    "payment_method": "liqpay",
    "order_id": "SUB_uuid_1696183200000",
    "description": "Підписка на план \"Власник Персональний\"",
    "created_at": "2025-10-01T19:00:00Z"
  },
  "plan": {
    "id": "uuid-plan-id",
    "name": "Власник Персональний",
    "price": 300,
    "currency": "UAH"
  },
  "payment_form": "<html><form method=\"POST\" action=\"https://www.liqpay.ua/api/3/checkout\"...></form></html>",
  "order_id": "SUB_uuid_1696183200000"
}
```

**Important Response Fields:**
- `payment_form` - HTML form that needs to be displayed to user
- `order_id` - Track this to check payment status later
- `subscription.status` - Will be "pending" until payment is completed

---

### 3. Display Payment Form in Mobile App

**Option A: WebView (Recommended)**

React Native example:
```typescript
import { WebView } from 'react-native-webview';

function PaymentScreen({ paymentForm, orderId }) {
  return (
    <WebView
      source={{ html: paymentForm }}
      onNavigationStateChange={(navState) => {
        // Check if payment is completed
        if (navState.url.includes('payment=success')) {
          // Payment successful, check status
          checkPaymentStatus(orderId);
        }
      }}
    />
  );
}
```

**Option B: Extract URL and Open Browser**

Parse the HTML form to get the action URL and parameters, then open in system browser:
```typescript
// The form posts to: https://www.liqpay.ua/api/3/checkout
// Extract data and signature from the HTML form
// Then open this URL in browser
```

---

### 4. Check Payment Status

```http
GET https://api-dev.sudnokontrol.online/api/subscriptions/payment/status/:order_id
Authorization: Bearer <jwt_token>
```

**Example:**
```http
GET https://api-dev.sudnokontrol.online/api/subscriptions/payment/status/SUB_uuid_1696183200000
```

**Response:**
```json
{
  "transaction_id": "uuid-transaction-id",
  "order_id": "SUB_uuid_1696183200000",
  "status": "completed",
  "amount": 300,
  "currency": "UAH",
  "description": "Підписка на план \"Власник Персональний\"",
  "created_at": "2025-10-01T19:00:00Z",
  "processed_at": "2025-10-01T19:05:30Z"
}
```

**Status Values:**
- `pending` - Payment not yet completed
- `processing` - Payment is being processed
- `completed` - ✅ Payment successful, subscription activated
- `failed` - ❌ Payment failed

---

### 5. Get Current User Subscription

```http
GET https://api-dev.sudnokontrol.online/api/subscriptions/my
Authorization: Bearer <jwt_token>
```

**Response (Active Subscription):**
```json
{
  "subscription": {
    "id": "uuid-subscription-id",
    "user_id": "user-uuid",
    "plan_id": "plan-uuid",
    "status": "active",
    "starts_at": "2025-10-01T19:00:00Z",
    "expires_at": "2025-11-01T19:00:00Z",
    "auto_renew": false,
    "usage_count": 5,
    "credits_remaining": 0,
    "plan_name": "Власник Персональний",
    "plan_type": "monthly_unlimited",
    "plan_price": 300,
    "plan_features": [
      "До 3 власних суден",
      "GPS трекінг",
      "Повідомлення про відправлення/прибуття"
    ],
    "usage_stats": {
      "total": 5,
      "this_month": 5,
      "this_week": 2
    }
  }
}
```

**Response (No Subscription):**
```json
{
  "subscription": null,
  "message": "No active subscription found"
}
```

---

### 6. Cancel Subscription

```http
POST https://api-dev.sudnokontrol.online/api/subscriptions/cancel
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "reason": "Too expensive" // Optional
}
```

**Response:**
```json
{
  "message": "Subscription cancelled successfully",
  "subscription": {
    "id": "uuid-subscription-id",
    "status": "cancelled",
    "cancelled_at": "2025-10-15T10:00:00Z",
    "cancellation_reason": "Too expensive"
  }
}
```

---

### 7. Check Usage Limits

```http
GET https://api-dev.sudnokontrol.online/api/subscriptions/usage/check-limit
Authorization: Bearer <jwt_token>
```

**Response (Unlimited Plan):**
```json
{
  "can_use": true,
  "subscription_type": "monthly_unlimited",
  "remaining_credits": null
}
```

**Response (Pay-per-use Plan with Credits):**
```json
{
  "can_use": true,
  "subscription_type": "pay_per_use",
  "remaining_credits": 5
}
```

**Response (No Credits):**
```json
{
  "can_use": false,
  "reason": "insufficient_credits",
  "subscription_type": "pay_per_use",
  "remaining_credits": 0
}
```

**Response (No Subscription):**
```json
{
  "can_use": false,
  "reason": "no_subscription",
  "message": "No active subscription found"
}
```

---

### 8. Get Payment History

```http
GET https://api-dev.sudnokontrol.online/api/subscriptions/payments/history?page=1&limit=20
Authorization: Bearer <jwt_token>
```

**Response:**
```json
{
  "transactions": [
    {
      "id": "uuid-tx-1",
      "amount": 300,
      "currency": "UAH",
      "status": "completed",
      "payment_method": "liqpay",
      "order_id": "SUB_uuid_1696183200000",
      "description": "Підписка на план \"Власник Персональний\"",
      "created_at": "2025-10-01T19:00:00Z",
      "processed_at": "2025-10-01T19:05:30Z"
    }
  ],
  "pagination": {
    "total": 1,
    "page": 1,
    "limit": 20,
    "pages": 1
  }
}
```

---

## 📱 Mobile App Implementation Guide

### 1. Subscription Plans Screen

**UI Components:**
- List of available plans with pricing
- "Current Plan" indicator if user has active subscription
- Features list for each plan
- "Subscribe" or "Choose Plan" button

**Implementation:**
```typescript
async function loadPlans() {
  const response = await fetch(
    'https://api-dev.sudnokontrol.online/api/subscriptions/plans',
    {
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    }
  );
  const data = await response.json();
  return data.plans;
}
```

---

### 2. Payment Flow Screen

**Step 1: User Selects Plan**
```typescript
async function subscribeToPlan(planId: string) {
  const response = await fetch(
    'https://api-dev.sudnokontrol.online/api/subscriptions/subscribe',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${userToken}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        plan_id: planId,
        auto_renew: false,
        payment_method: 'liqpay'
      })
    }
  );
  
  const data = await response.json();
  return {
    paymentForm: data.payment_form,
    orderId: data.order_id,
    subscriptionId: data.subscription.id
  };
}
```

**Step 2: Display Payment Form**
```typescript
import { WebView } from 'react-native-webview';

function LiqPayPayment({ paymentForm, orderId, onSuccess, onCancel }) {
  const [checking, setChecking] = useState(false);

  const handleNavigationChange = async (navState) => {
    // Check if user returned from payment
    if (navState.url.includes('sudnokontrol.online')) {
      setChecking(true);
      
      // Wait a few seconds for webhook to process
      await new Promise(resolve => setTimeout(resolve, 3000));
      
      // Check payment status
      const status = await checkPaymentStatus(orderId);
      
      if (status === 'completed') {
        onSuccess();
      } else if (status === 'failed') {
        Alert.alert('Payment Failed', 'Your payment was not successful');
        onCancel();
      }
    }
  };

  return (
    <View style={{ flex: 1 }}>
      <WebView
        source={{ html: paymentForm }}
        onNavigationStateChange={handleNavigationChange}
      />
      {checking && <LoadingOverlay message="Checking payment status..." />}
    </View>
  );
}
```

**Step 3: Check Payment Status**
```typescript
async function checkPaymentStatus(orderId: string): Promise<string> {
  const response = await fetch(
    `https://api-dev.sudnokontrol.online/api/subscriptions/payment/status/${orderId}`,
    {
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    }
  );
  
  const data = await response.json();
  return data.status; // 'pending' | 'completed' | 'failed'
}
```

**Step 4: Refresh User Profile**
```typescript
async function refreshUserProfile() {
  // Re-fetch user profile to get updated subscription_status
  const response = await fetch(
    'https://api-dev.sudnokontrol.online/api/auth/profile',
    {
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    }
  );
  
  const data = await response.json();
  // Update user state with new subscription_status
  setUser(data.user);
}
```

---

### 3. Subscription Status Display

**UI Components Needed:**

**Active Subscription Badge:**
```typescript
function SubscriptionBadge({ user }) {
  if (user.subscription_status === 'trial') {
    return (
      <View style={styles.trialBadge}>
        <Text>Free Trial - {user.trial_days_remaining} days left</Text>
      </View>
    );
  }
  
  if (user.subscription_status === 'active') {
    return (
      <View style={styles.activeBadge}>
        <Text>Premium Active</Text>
      </View>
    );
  }
  
  return null;
}
```

**Subscription Expired Screen:**
```typescript
function SubscriptionRequired({ onSubscribe }) {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Subscription Required</Text>
      <Text style={styles.message}>
        Your trial has ended. Choose a subscription plan to continue using SudnoKontrol.
      </Text>
      <Button title="View Plans" onPress={onSubscribe} />
    </View>
  );
}
```

**Trial Ending Warning:**
```typescript
function TrialWarning({ daysRemaining }) {
  if (daysRemaining > 7) return null;
  
  return (
    <View style={styles.warningBanner}>
      <Text>Your trial expires in {daysRemaining} days. Subscribe now!</Text>
      <Button title="Subscribe" onPress={() => navigation.navigate('Plans')} />
    </View>
  );
}
```

---

### 4. Usage Tracking

**Before Critical Actions:**
```typescript
async function performVerification() {
  // Check if user can perform action
  const response = await fetch(
    'https://api-dev.sudnokontrol.online/api/subscriptions/usage/check-limit',
    {
      headers: {
        'Authorization': `Bearer ${userToken}`
      }
    }
  );
  
  const data = await response.json();
  
  if (!data.can_use) {
    if (data.reason === 'no_subscription') {
      // Show "Subscribe Now" screen
      navigation.navigate('SubscriptionPlans');
    } else if (data.reason === 'insufficient_credits') {
      // Show "Buy More Credits" screen
      Alert.alert('No Credits', 'You need to purchase more credits to continue.');
    }
    return;
  }
  
  // Proceed with verification
  await doVerification();
}
```

---

## 🧪 Testing in Sandbox

### Test Credit Cards

LiqPay sandbox accepts these test cards:

**Successful Payment:**
```
Card Number: 4242 4242 4242 4242
Expiry: Any future date (e.g., 12/25)
CVV: Any 3 digits (e.g., 123)
```

**Failed Payment:**
```
Card Number: 4000 0000 0000 0002
Expiry: Any future date
CVV: Any 3 digits
```

### Test Flow

1. Login to mobile app with test user
2. Navigate to subscription plans
3. Select a plan and tap "Subscribe"
4. Complete payment with test card above
5. Return to app
6. Refresh profile - `subscription_status` should be "active"
7. Check subscription details in profile

---

## ⚠️ Important Notes

### Payment Status Polling

After payment, the webhook may take a few seconds to process. Implement polling:

```typescript
async function waitForPaymentConfirmation(orderId: string, maxAttempts = 10) {
  for (let i = 0; i < maxAttempts; i++) {
    const status = await checkPaymentStatus(orderId);
    
    if (status === 'completed') {
      return true;
    }
    
    if (status === 'failed') {
      return false;
    }
    
    // Wait 2 seconds before next check
    await new Promise(resolve => setTimeout(resolve, 2000));
  }
  
  return null; // Status still pending after max attempts
}
```

### Error Handling

```typescript
try {
  const result = await subscribeToPlan(planId);
  // Show payment form
} catch (error) {
  if (error.message.includes('already has an active subscription')) {
    Alert.alert('Already Subscribed', 'You already have an active subscription');
  } else {
    Alert.alert('Error', 'Failed to create subscription. Please try again.');
  }
}
```

### Subscription Lifecycle

```
Trial (30 days) → Expires → User subscribes → Active → 
  → Expires → User renews → Active (continues)
                  ↓
              User cancels → Cancelled (access until expiry date)
```

---

## 🔧 Troubleshooting

### Payment Not Activating

**Problem:** Payment completed but subscription still shows "pending"

**Solutions:**
1. Wait 5-10 seconds and check status again
2. Check backend logs for webhook errors
3. Verify webhook URL is configured in LiqPay merchant dashboard
4. Contact backend developer with order_id

### WebView Not Loading

**Problem:** Payment form doesn't display in WebView

**Solutions:**
1. Ensure JavaScript is enabled in WebView
2. Check `payment_form` HTML is not empty
3. Try opening in external browser as fallback

### Status Always Pending

**Problem:** `checkPaymentStatus` always returns "pending"

**Solutions:**
1. Verify order_id is correct
2. Check if payment was actually completed
3. Check backend webhook logs
4. Try refreshing user profile instead

---

## 📞 Support Contacts

**Backend Developer:** Check `/var/www/sudnokontrol.online/LIQPAY_INTEGRATION_COMPLETE.md`  
**LiqPay Documentation:** https://www.liqpay.ua/documentation/uk  
**Backend API:** https://api-dev.sudnokontrol.online  
**Admin Dashboard:** https://dev.sudnokontrol.online/subscriptions

---

**Last Updated:** October 1, 2025 - 19:30 EEST  
**Integration Status:** ✅ Fully Operational (Sandbox Mode)

