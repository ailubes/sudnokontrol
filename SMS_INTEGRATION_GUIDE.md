# 📱 SMS Verification Integration Guide

## Overview

SudnoKontrol now supports SMS verification via **Turbosms.ua**, a popular SMS gateway service in Ukraine. This guide covers integration, testing, and troubleshooting.

---

## 🚀 Quick Start

### 1. Get Turbosms API Key

1. Register at [https://turbosms.ua/](https://turbosms.ua/)
2. Purchase SMS credits
3. Navigate to **API Settings** in your account
4. Copy your **API Token**

### 2. Configure Backend

Edit `.env` file in backend:

```bash
# Enable SMS Service
TURBOSMS_ENABLED=true

# Add your API key from Turbosms.ua
TURBOSMS_API_KEY=your-actual-api-key-here

# Customize sender name (max 11 characters, Latin only)
TURBOSMS_SENDER=SudnoKontrol
```

### 3. Restart Backend

```bash
cd /var/www/sudnokontrol.online/environments/development/backend/backend
npm run build
npm run dev
```

---

## 📋 SMS Verification Flow

### Registration with SMS Verification

```javascript
// 1. User registers
POST https://api-dev.sudnokontrol.online/api/auth/register
Content-Type: application/json

{
  "phone": "+380501234567",
  "email": "user@example.com",
  "first_name": "Іван",
  "last_name": "Петренко",
  "password": "securePassword123"
}

// Response
{
  "message": "User registered successfully. Please verify your phone number.",
  "user": {
    "id": "uuid",
    "phone": "+380501234567",
    "status": "pending",
    "phone_verified": false,
    "role": "ship_owner"
  }
}

// SMS sent to +380501234567:
// "Ваш код підтвердження SudnoKontrol: 123456
//
//  Код дійсний 15 хвилин.
//
//  Не передавайте код третім особам."
```

### Verify Phone Number

```javascript
// 2. User enters code from SMS
POST https://api-dev.sudnokontrol.online/api/auth/verify-phone
Content-Type: application/json

{
  "phone": "+380501234567",
  "code": "123456"
}

// Success Response
{
  "message": "Phone number verified successfully",
  "user": {
    "id": "uuid",
    "phone": "+380501234567",
    "status": "verified",
    "phone_verified": true,
    "role": "ship_owner"
  }
}

// Error Response (invalid code)
{
  "error": "Invalid or expired verification code"
}
```

### Resend Verification Code

```javascript
// 3. Request new code if expired
POST https://api-dev.sudnokontrol.online/api/auth/resend-verification
Content-Type: application/json

{
  "phone": "+380501234567"
}

// Response
{
  "message": "Verification code sent successfully"
}
```

---

## 🧪 Testing SMS Integration

### Without SMS (Development Mode)

When `TURBOSMS_ENABLED=false`, codes are only logged to console:

```bash
# Watch backend logs
tail -f /tmp/dev-backend.log | grep "Verification code"

# Output:
# [info]: Verification code for +380501234567: 123456
```

### Testing with SMS (Production Mode)

1. Enable SMS in `.env`:
   ```bash
   TURBOSMS_ENABLED=true
   TURBOSMS_API_KEY=your-real-api-key
   ```

2. Register a test user with your real phone number:
   ```bash
   curl -X POST https://api-dev.sudnokontrol.online/api/auth/register \
     -H "Content-Type: application/json" \
     -d '{
       "phone": "+380501234567",
       "email": "test@example.com",
       "first_name": "Test",
       "last_name": "User",
       "password": "test123"
     }'
   ```

3. Check your phone for SMS
4. Verify with received code:
   ```bash
   curl -X POST https://api-dev.sudnokontrol.online/api/auth/verify-phone \
     -H "Content-Type: application/json" \
     -d '{
       "phone": "+380501234567",
       "code": "123456"
     }'
   ```

---

## 📱 Mobile App Integration

### React Native / Expo Example

```javascript
// services/auth.js
import axios from 'axios';

const API_BASE = 'https://api-dev.sudnokontrol.online/api';

export const authService = {
  // Step 1: Register user
  async register(userData) {
    const response = await axios.post(`${API_BASE}/auth/register`, {
      phone: userData.phone,
      email: userData.email,
      first_name: userData.firstName,
      last_name: userData.lastName,
      password: userData.password
    });
    return response.data;
  },

  // Step 2: Verify phone with SMS code
  async verifyPhone(phone, code) {
    const response = await axios.post(`${API_BASE}/auth/verify-phone`, {
      phone,
      code
    });
    return response.data;
  },

  // Step 3: Resend code if needed
  async resendCode(phone) {
    const response = await axios.post(`${API_BASE}/auth/resend-verification`, {
      phone
    });
    return response.data;
  }
};
```

### UI Flow Example

```javascript
// screens/RegisterScreen.js
import { useState } from 'react';
import { authService } from '../services/auth';

export default function RegisterScreen({ navigation }) {
  const [phone, setPhone] = useState('');
  const [userData, setUserData] = useState({});

  const handleRegister = async () => {
    try {
      const result = await authService.register({
        phone,
        email: userData.email,
        firstName: userData.firstName,
        lastName: userData.lastName,
        password: userData.password
      });

      // Navigate to verification screen
      navigation.navigate('VerifyPhone', { phone });
    } catch (error) {
      alert(error.response?.data?.error || 'Registration failed');
    }
  };

  return (
    // Your registration form UI
  );
}

// screens/VerifyPhoneScreen.js
export default function VerifyPhoneScreen({ route, navigation }) {
  const { phone } = route.params;
  const [code, setCode] = useState('');
  const [countdown, setCountdown] = useState(15 * 60); // 15 minutes

  const handleVerify = async () => {
    try {
      const result = await authService.verifyPhone(phone, code);

      // Success! Navigate to main app
      navigation.navigate('Home');
    } catch (error) {
      alert('Invalid code. Please try again.');
    }
  };

  const handleResend = async () => {
    try {
      await authService.resendCode(phone);
      setCountdown(15 * 60);
      alert('New code sent!');
    } catch (error) {
      alert('Failed to resend code');
    }
  };

  return (
    // Your verification UI with:
    // - 6-digit code input
    // - Timer showing code expiration
    // - Resend button (enabled after timer expires)
  );
}
```

### Swift (iOS) Example

```swift
// AuthService.swift
import Foundation

struct AuthService {
    let baseURL = "https://api-dev.sudnokontrol.online/api"

    func register(phone: String, email: String, firstName: String,
                  lastName: String, password: String) async throws {
        let url = URL(string: "\(baseURL)/auth/register")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "phone": phone,
            "email": email,
            "first_name": firstName,
            "last_name": lastName,
            "password": password
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        // Handle response
    }

    func verifyPhone(phone: String, code: String) async throws {
        let url = URL(string: "\(baseURL)/auth/verify-phone")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["phone": phone, "code": code]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        // Handle response
    }
}
```

### Kotlin (Android) Example

```kotlin
// AuthService.kt
import retrofit2.http.*

interface AuthService {
    @POST("auth/register")
    suspend fun register(
        @Body request: RegisterRequest
    ): Response<RegisterResponse>

    @POST("auth/verify-phone")
    suspend fun verifyPhone(
        @Body request: VerifyPhoneRequest
    ): Response<VerifyPhoneResponse>

    @POST("auth/resend-verification")
    suspend fun resendCode(
        @Body request: ResendCodeRequest
    ): Response<ResendCodeResponse>
}

data class RegisterRequest(
    val phone: String,
    val email: String,
    val first_name: String,
    val last_name: String,
    val password: String
)

data class VerifyPhoneRequest(
    val phone: String,
    val code: String
)
```

---

## 🔧 Technical Details

### SMS Service Architecture

**File**: `src/services/smsService.ts`

```typescript
class SMSService {
  // Send verification code SMS
  async sendVerificationCode(phone: string, code: string)

  // Send trip notification SMS to DPSU
  async sendTripNotification(phone: string, vesselName: string, ...)

  // Check if SMS is enabled
  isEnabled(): boolean

  // Get service status
  getStatus(): { enabled, configured, sender }
}
```

### Verification Code Spec

- **Format**: 6 digits (e.g., `123456`)
- **Validity**: 15 minutes
- **Generation**: Random, cryptographically secure
- **Storage**: Hashed in database with expiration timestamp

### Database Fields

Table: `users`

| Field | Type | Description |
|-------|------|-------------|
| `phone_verified` | boolean | Is phone verified? |
| `verification_code` | varchar(6) | Current verification code |
| `verification_expires_at` | timestamp | Code expiration time |
| `status` | enum | `pending` → `verified` after SMS verification |

### Rate Limiting

SMS endpoints are rate-limited:

- **Register**: 5 requests/15 minutes per IP
- **Verify**: 10 attempts per phone number
- **Resend**: 3 requests/hour per phone number

---

## 💰 Turbosms Pricing

**As of 2025** (check [turbosms.ua](https://turbosms.ua/ua/price.html) for current prices):

- SMS to Ukrainian numbers: ~0.50 - 1.50 UAH per message
- Bulk discounts available
- Prepaid credits system

**Cost Estimation:**
- 1000 registrations = 1000 SMS ≈ 500-1500 UAH
- Include resend codes in budget (~20% extra)

---

## 🐛 Troubleshooting

### SMS Not Sending

**Symptom**: User doesn't receive SMS, but registration succeeds

**Check:**
1. Is SMS enabled?
   ```bash
   grep TURBOSMS_ENABLED .env
   ```

2. Is API key valid?
   ```bash
   tail -f /tmp/dev-backend.log | grep "SMS Service"
   ```

3. Check Turbosms balance:
   - Login to [turbosms.ua](https://turbosms.ua/)
   - Check account balance
   - Verify API key permissions

**Solution:**
- Enable SMS: `TURBOSMS_ENABLED=true`
- Add valid API key
- Top up Turbosms account

### Code Already Expired

**Symptom**: "Invalid or expired verification code"

**Cause**: Code expires after 15 minutes

**Solution:**
```javascript
// Request new code
POST /api/auth/resend-verification
{
  "phone": "+380501234567"
}
```

### Invalid Phone Format

**Symptom**: 400 error on registration

**Cause**: Phone must be in international format

**Valid formats:**
- ✅ `+380501234567`
- ✅ `+38 050 123 45 67`
- ❌ `0501234567`
- ❌ `501234567`

### SMS Service Disabled in Development

**This is normal!** When testing locally:

1. Check logs for verification code:
   ```bash
   tail -f /tmp/dev-backend.log | grep "Verification code"
   ```

2. Use logged code to verify:
   ```bash
   curl -X POST https://api-dev.sudnokontrol.online/api/auth/verify-phone \
     -H "Content-Type: application/json" \
     -d '{"phone": "+380501234567", "code": "CODE_FROM_LOGS"}'
   ```

---

## 🔐 Security Considerations

### Best Practices

1. **Never expose API keys**
   - Keep `TURBOSMS_API_KEY` in `.env` only
   - Don't commit to Git
   - Use different keys for dev/prod

2. **Rate limiting**
   - Prevents SMS bombing attacks
   - Already implemented in backend

3. **Code expiration**
   - 15-minute validity
   - One-time use only

4. **Phone verification is required**
   - Users can't use app without verified phone
   - `status: 'pending'` until verified

### Manual Verification (Testing Only)

For testing, you can manually verify users:

```sql
UPDATE users
SET phone_verified = true,
    status = 'verified'
WHERE phone = '+380501234567';
```

---

## 📊 Monitoring

### Check SMS Service Status

**Via Logs:**
```bash
tail -f /tmp/dev-backend.log | grep "SMS Service"
```

**Via Code:**
```typescript
import { smsService } from './services/smsService';

const status = smsService.getStatus();
console.log(status);
// { enabled: true, configured: true, sender: 'SudnoKontrol' }
```

### SMS Metrics to Track

- Total SMS sent
- SMS delivery rate
- Failed SMS attempts
- Verification success rate
- Average time to verify
- SMS costs

---

## 🚀 Production Deployment

### Checklist

- [ ] Get Turbosms.ua account and API key
- [ ] Top up SMS credits
- [ ] Update production `.env`:
  ```bash
  TURBOSMS_ENABLED=true
  TURBOSMS_API_KEY=prod-api-key-here
  TURBOSMS_SENDER=SudnoKontrol
  ```
- [ ] Test SMS sending with real phone number
- [ ] Monitor SMS delivery rates
- [ ] Set up alerts for low SMS balance
- [ ] Update mobile app with verification UI
- [ ] Test complete registration flow
- [ ] Update MOBILE-API.md documentation

### Environment Variables Summary

| Variable | Development | Production |
|----------|-------------|------------|
| `TURBOSMS_ENABLED` | `false` | `true` |
| `TURBOSMS_API_KEY` | `test-key` or empty | Real API key |
| `TURBOSMS_SENDER` | `SudnoKontrol` | `SudnoKontrol` |

---

## 📚 Related Documentation

- [MOBILE-API.md](./MOBILE-API.md) - Complete Mobile API Reference
- [MOBILE_API_MONITORING.md](./MOBILE_API_MONITORING.md) - API Monitoring Guide
- [MOBILE_DOCS_INDEX.md](./MOBILE_DOCS_INDEX.md) - Documentation Hub
- [Turbosms API Docs](https://turbosms.ua/api.html) - Official Turbosms Documentation

---

## 🆘 Support

**Technical Issues:**
- Backend: Check logs at `/tmp/dev-backend.log`
- Turbosms: [support@turbosms.ua](mailto:support@turbosms.ua)
- SudnoKontrol: See MOBILE_DOCS_INDEX.md for contacts

**Turbosms Support:**
- Website: [https://turbosms.ua/](https://turbosms.ua/)
- Phone: +380 (44) 468-09-00
- Email: support@turbosms.ua

---

*🇺🇦 SudnoKontrol SMS Integration*
*Last Updated: October 1, 2025*
